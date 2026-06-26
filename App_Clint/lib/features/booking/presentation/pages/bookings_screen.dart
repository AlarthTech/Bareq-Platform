import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bottom_nav_bar.dart';
import '../../../../core/di/injection_container.dart';
import '../../presentation/state/booking_realtime_cubit.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status_codes.dart';
import '../../domain/entities/booking_sort_option.dart';
import '../../domain/entities/work_type_detail.dart';
import '../../domain/usecases/get_my_bookings_page_usecase.dart';
import '../../../../core/network/pagination_constants.dart';
import '../../../../core/utils/failure_ui.dart';
import '../../domain/usecases/get_all_work_types_usecase.dart';
import '../../../../core/widgets/common/app_empty_state.dart';
import '../widgets/booking_card.dart';
import '../utils/booking_customer_status_display.dart';
import '../../../reviews/presentation/models/rate_worker_args.dart';
import '../../../reviews/presentation/state/booking_review_status_cubit.dart';
import '../../../notifications/presentation/state/notifications_cubit.dart';

/// Bookings Screen - Displays user's bookings
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<Booking> _bookings = [];
  List<WorkTypeDetail> _workTypes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = PaginationConstants.defaultPage;
  int? _userId;
  String? _errorMessage;
  BookingSortOption _sortOption = BookingSortOption.bookingDateNewest;
  late final BookingReviewStatusCubit _reviewStatusCubit;
  StreamSubscription<BookingRealtimeState>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 6, vsync: this);
    _scrollController.addListener(_onScrollNearEnd);
    _reviewStatusCubit = sl<BookingReviewStatusCubit>();
    _realtimeSubscription =
        sl<BookingRealtimeCubit>().stream.listen(_onBookingStatusRealtime);
    _loadBookings();
  }

  void _onBookingStatusRealtime(BookingRealtimeState state) {
    final event = state.latest;
    if (event == null || !mounted) return;

    final index = _bookings.indexWhere((b) => b.id == event.bookingId);
    if (index < 0) return;

    if (_bookings[index].status == event.statusCode) return;

    setState(() {
      _bookings[index] =
          _bookings[index].copyWith(status: event.statusCode);
    });

    if (event.statusCode == BookingStatusCodes.completed) {
      _reviewStatusCubit.check(event.bookingId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeSubscription?.cancel();
    _scrollController.removeListener(_onScrollNearEnd);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScrollNearEnd() {
    if (!_scrollController.hasClients || _userId == null) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _fetchBookingsPage(_userId!, reset: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load current user first
      final getCurrentUserUseCase = sl<GetCurrentUserUseCase>();
      final userResult = await getCurrentUserUseCase();

      userResult.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Please log in to view bookings';
            });
          }
        },
        (user) async {
          if (user == null) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Please log in to view bookings';
              });
            }
            return;
          }

          final userId = int.tryParse(user.id);
          if (userId == null) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Invalid user id';
              });
            }
            return;
          }

          _userId = userId;
          await Future.wait([
            _fetchBookingsPage(userId, reset: true),
            _fetchWorkTypes(),
          ]);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load bookings: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _fetchWorkTypes() async {
    try {
      final getAllWorkTypesUseCase = sl<GetAllWorkTypesUseCase>();
      final result = await getAllWorkTypesUseCase();

      result.fold(
        (failure) {
          // Handle error silently - work types are optional
          if (mounted) {
            setState(() {
              _workTypes = [];
            });
          }
        },
        (workTypes) {
          if (mounted) {
            setState(() {
              _workTypes = workTypes;
            });
          }
        },
      );
    } catch (e) {
      // Handle error silently
      if (mounted) {
        setState(() {
          _workTypes = [];
        });
      }
    }
  }

  String _bookingsListErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      final code = failure.statusCode;
      if (code == 500 || code == 502 || code == 503 || code == 504) {
        return L10n.translate(context, 'bookingsListServerUnavailable');
      }
    }
    return failureMessage(context, failure);
  }

  Future<void> _fetchBookingsPage(int userId, {required bool reset}) async {
    if (reset) {
      if (_isLoadingMore) return;
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _currentPage = PaginationConstants.defaultPage;
          _hasMore = true;
          if (reset) _bookings = [];
        });
      }
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      if (mounted) setState(() => _isLoadingMore = true);
    }

    final page =
        reset ? PaginationConstants.defaultPage : _currentPage + 1;

    try {
      final result = await sl<GetMyBookingsPageUseCase>()(
        userId,
        page: page,
        pageSize: PaginationConstants.defaultPageSize,
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _errorMessage = _bookingsListErrorMessage(failure);
          });
        },
        (paged) {
          if (!mounted) return;
          setState(() {
            if (reset) {
              _bookings = paged.items;
            } else {
              final ids = _bookings.map((b) => b.id).toSet();
              _bookings.addAll(
                paged.items.where((b) => ids.add(b.id)),
              );
            }
            _currentPage = page;
            _hasMore = paged.hasNextPage;
            _isLoading = false;
            _isLoadingMore = false;
          });
          _refreshReviewStatuses(
            reset ? paged.items : _bookings,
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'Failed to load bookings: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _refreshReviewStatuses(List<Booking> bookings) async {
    final completed = bookings.where(
      (b) => b.status == BookingStatusCodes.completed,
    );
    await Future.wait(
      completed.map((b) => _reviewStatusCubit.check(b.id)),
    );
    if (mounted) setState(() {});
  }

  List<Booking> _getFilteredBookings(String? status) {
    final List<Booking> filtered;
    if (status == null || status == 'all') {
      filtered = List<Booking>.from(_bookings);
    } else if (status == 'in_progress') {
      filtered =
          _bookings
              .where((b) => BookingStatusCodes.isInProgress(b.status))
              .toList();
    } else if (status == 'canceled') {
      filtered = _bookings.where((b) => b.status == BookingStatusCodes.canceled).toList();
    } else if (status == 'rejected') {
      filtered = _bookings.where((b) => b.status == BookingStatusCodes.rejected).toList();
    } else {
      filtered =
          _bookings
              .where((booking) => booking.statusString == status)
              .toList();
    }

    _sortOption.sort(filtered);
    return filtered;
  }

  String _sortOptionLabel(BuildContext context) {
    final l10n = L10n.of(context);
    return l10n?.translate(_sortOption.localizationKey()) ??
        _sortOption.localizationKey();
  }

  Future<void> _showSortOptions() async {
    final l10n = L10n.of(context);
    final selected = await showModalBottomSheet<BookingSortOption>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.translate('sortBookings') ?? 'Sort bookings',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...BookingSortOption.values.map(
                (option) {
                  final isSelected = option == _sortOption;
                  return ListTile(
                    title: Text(
                      l10n?.translate(option.localizationKey()) ??
                          option.localizationKey(),
                      style: Theme.of(sheetContext).textTheme.bodyLarge
                          ?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, option),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() => _sortOption = selected);
  }

  Widget _buildSortBar(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 10),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton.icon(
          onPressed: _showSortOptions,
          icon: const Icon(Icons.swap_vert, size: 20),
          label: Text(
            '${l10n?.translate('sortBy') ?? 'Sort'}: ${_sortOptionLabel(context)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('myBookings') ?? AppStrings.myBookings,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    onTap: (index) {
                      setState(() {});
                    },
                    tabs: [
                      Tab(text: l10n?.translate('all') ?? AppStrings.all),
                      Tab(text: l10n?.translate('pending') ?? AppStrings.pending),
                      Tab(
                        text: l10n?.translate('bookingsTabInProgress') ??
                            'In progress',
                      ),
                      Tab(
                        text: l10n?.translate('completed') ??
                            AppStrings.completed,
                      ),
                      Tab(text: l10n?.translate('canceled') ?? 'Canceled'),
                      Tab(text: l10n?.translate('rejected') ?? 'Rejected'),
                    ],
                  ),
          ),
          if (!_isLoading && _errorMessage == null) _buildSortBar(context),

          // Bookings List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? AppEmptyState(
                      icon: Icons.error_outline,
                      title: l10n?.translate('error') ?? AppStrings.error,
                      subtitle: _errorMessage!,
                      actionLabel: l10n?.translate('retry') ?? AppStrings.retry,
                      onAction: _loadBookings,
                    )
                    : Builder(
                      builder: (context) {
                        String? selectedStatus;
                        switch (_tabController.index) {
                          case 0:
                            selectedStatus = 'all';
                            break;
                          case 1:
                            selectedStatus = 'pending';
                            break;
                          case 2:
                            selectedStatus = 'in_progress';
                            break;
                          case 3:
                            selectedStatus = 'completed';
                            break;
                          case 4:
                            selectedStatus = 'canceled';
                            break;
                          case 5:
                            selectedStatus = 'rejected';
                            break;
                        }

                        final filteredBookings = _getFilteredBookings(
                          selectedStatus,
                        );

                        return filteredBookings.isEmpty
                            ? _buildEmptyState(context)
                            : RefreshIndicator(
                              onRefresh: () async {
                                await Future.wait([
                                  _loadBookings(),
                                  sl<NotificationsCubit>().refreshFromServer(),
                                ]);
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20),
                                itemCount: filteredBookings.length +
                                    (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= filteredBookings.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return _buildBookingCard(
                                    context,
                                    filteredBookings[index],
                                  );
                                },
                              ),
                            );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final l10n = L10n.of(context);
    final locale = l10n?.locale ?? const Locale('en');

    // Find matching work type by matching workerWorkTypeId with work type id
    WorkTypeDetail? foundWorkType;
    try {
      foundWorkType = _workTypes.firstWhere(
        (wt) => wt.id == booking.workerWorkTypeId,
      );
    } catch (e) {
      foundWorkType = null;
    }

    final workType =
        foundWorkType ??
        WorkTypeDetail(
          id: 0,
          name: '',
          companyId: 0,
          companyName: '',
          startTime: '',
          endTime: '',
          isOvernight: false,
          price: 0.0,
          isActive: false,
          createdAt: DateTime.now(),
        );

    // Format booking date
    final formattedDate = WesternNumerals.normalize(
      DateFormat.yMMMd(
        locale.toString(),
      ).format(booking.bookingDate),
    );

    // Format booking time - use work type times if available, otherwise use booking dates
    String bookingTime;
    if (workType.startTime.isNotEmpty && workType.endTime.isNotEmpty) {
      // Use work type time range
      bookingTime = '${workType.startTime} - ${workType.endTime}';
    } else if (booking.startDate != null && booking.endDate != null) {
      // Check if it's the same day (single day booking)
      final isSameDay =
          booking.startDate!.year == booking.endDate!.year &&
          booking.startDate!.month == booking.endDate!.month &&
          booking.startDate!.day == booking.endDate!.day;

      if (isSameDay) {
        // Single day booking - show time range
        final startTime = WesternNumerals.normalize(
          DateFormat('HH:mm').format(booking.startDate!),
        );
        final endTime = WesternNumerals.normalize(
          DateFormat('HH:mm').format(booking.endDate!),
        );
        bookingTime = '$startTime - $endTime';
      } else {
        // Overnight booking - show date range
        final startDate = WesternNumerals.normalize(
          DateFormat(
            'MMM d',
            locale.toString(),
          ).format(booking.startDate!),
        );
        final endDate = WesternNumerals.normalize(
          DateFormat(
            'MMM d',
            locale.toString(),
          ).format(booking.endDate!),
        );
        bookingTime = '$startDate - $endDate';
      }
    } else {
      bookingTime = l10n?.translate('timeNotSpecified') ?? 'Time not specified';
    }

    // Service type - use work type name
    String serviceType =
        workType.name.isNotEmpty
            ? workType.name
            : (l10n?.translate('service') ?? 'Service');

    final price = booking.totalPrice;
    final hasPricing = booking.hasStoredPricing;

    final locationLabel =
        booking.locationName?.trim().isNotEmpty == true
            ? booking.locationName!
            : (booking.address.trim().isNotEmpty ? booking.address : null);

    return BookingCard(
      maidName: booking.workerName,
      maidAvatarUrl: '',
      companyName: booking.companyName,
      bookingDate: formattedDate,
      bookingTime: bookingTime,
      serviceType: serviceType,
      locationLabel: locationLabel,
      status: BookingCustomerStatusDisplay.displayStatusKey(booking),
      price: price,
      hasPricing: hasPricing,
      bookingId: booking.id.toString(),
      workerId: booking.workerId,
      serviceId: booking.workerWorkTypeId,
      hasReview: booking.status == BookingStatusCodes.completed
          ? _reviewStatusCubit.getCached(booking.id)
          : null,
      onRate: () async {
        final changed = await context.push<bool>(
          AppStrings.routeRateWorker,
          extra: RateWorkerArgs(
            bookingId: booking.id,
            workerId: booking.workerId,
            workerName: booking.workerName,
            companyId: booking.companyId,
            companyName: booking.companyName,
          ),
        );
        if (changed == true && mounted) {
          _reviewStatusCubit.markReviewed(booking.id);
          setState(() {});
        }
      },
      onViewReview: () async {
        final changed = await context.push<bool>(
          AppStrings.myReviewRoute(booking.id),
        );
        if (changed == true && mounted) {
          await _reviewStatusCubit.check(booking.id);
          setState(() {});
        }
      },
      onTap: () {
        context.push(AppStrings.bookingDetailsRoute(booking.id.toString()));
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = L10n.of(context);
    final isAllTab = _tabController.index == 0;
    return AppEmptyState(
      icon: Icons.calendar_today_outlined,
      title:
          isAllTab
              ? (l10n?.translate('noBookingsYet') ?? 'No Bookings Yet')
              : (l10n?.translate('noBookingsForStatus') ??
                  'No bookings in this category'),
      subtitle:
          isAllTab
              ? (l10n?.translate('yourBookingsWillAppearHere') ??
                  'Your bookings will appear here')
              : (l10n?.translate('noBookingsForStatusHint') ??
                  'Try another tab or book from Home.'),
      actionLabel: l10n?.translate('exploreHome') ?? 'Explore Home',
      onAction: () => context.go(AppStrings.routeHome),
    );
  }
}
