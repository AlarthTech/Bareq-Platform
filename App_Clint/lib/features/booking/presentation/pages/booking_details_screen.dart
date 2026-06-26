import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../presentation/state/booking_realtime_cubit.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/utils/shift_hours_formatter.dart';
import '../../../../core/company/company_monthly_fee_store.dart';
import '../../domain/entities/work_type.dart';
import '../../domain/usecases/get_worker_work_types_usecase.dart';
import '../../../companies/domain/usecases/get_company_by_id_usecase.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../auth/domain/entities/app_user_role.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/booking.dart';
import '../../../booking_pricing/domain/entities/booking_price_breakdown.dart';
import '../../../booking_pricing/presentation/widgets/booking_price_breakdown_card.dart';
import '../../domain/entities/booking_status_codes.dart';
import '../../domain/usecases/get_company_bookings_usecase.dart';
import '../../../../core/auth/jwt_claims_helper.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import '../../domain/usecases/confirm_worker_arrival_usecase.dart';
import '../../domain/usecases/update_booking_status_usecase.dart';
import '../utils/booking_customer_status_display.dart';
import '../widgets/booking_status_timeline.dart';
import '../widgets/booking_wallet_status_card.dart';
import '../../../reviews/presentation/models/rate_worker_args.dart';
import '../../../reviews/presentation/state/booking_review_status_cubit.dart';
import '../../../booking_reports/domain/usecases/get_booking_reports_by_booking_usecase.dart';
import '../../../booking_reports/presentation/models/create_booking_report_args.dart';
import '../../../booking_reports/presentation/utils/booking_report_policy.dart';

/// Booking detail: API workflow, customer vs company actions, refresh on resume / poll.
class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen>
    with WidgetsBindingObserver {
  Booking? _booking;
  WorkType? _workType;
  double _monthlyAccommodationFeePerMonth = 0;
  bool _loading = true;
  String? _errorMessage;
  bool _updating = false;
  AppUserRole? _role;
  Timer? _pollTimer;
  bool? _hasReview;
  bool _hasActiveBookingReport = false;
  bool _loadingBookingReports = false;
  late final BookingReviewStatusCubit _reviewStatusCubit;
  StreamSubscription<BookingRealtimeState>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reviewStatusCubit = sl<BookingReviewStatusCubit>();
    _realtimeSubscription =
        sl<BookingRealtimeCubit>().stream.listen(_onBookingStatusRealtime);
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _booking == null) return;
      if (BookingStatusCodes.isTerminal(_booking!.status)) return;
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _onBookingStatusRealtime(BookingRealtimeState state) {
    final event = state.latest;
    final bookingId = int.tryParse(widget.bookingId);
    if (event == null || bookingId == null || event.bookingId != bookingId) {
      return;
    }
    if (_booking == null || !mounted) return;

    final previousStatus = _booking!.status;
    if (previousStatus == event.statusCode) return;

    setState(() {
      _booking = _booking!.copyWith(status: event.statusCode);
    });

    if (BookingStatusCodes.isTerminal(event.statusCode)) {
      _pollTimer?.cancel();
    }

    if (_isCustomer &&
        event.statusCode == BookingStatusCodes.completed &&
        previousStatus != BookingStatusCodes.completed) {
      _loadReviewStatus(bookingId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  bool get _isCustomer =>
      _role == null || _role == AppUserRole.customer;

  bool get _isCompanyStaff =>
      _role == AppUserRole.company || _role == AppUserRole.admin;

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final id = int.tryParse(widget.bookingId);
    if (id == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'bookingNotFound';
        });
      }
      return;
    }

    final userRes = await sl<GetCurrentUserUseCase>()();
    await userRes.fold(
      (_) async {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'bookingLoadError';
          });
        }
      },
      (user) async {
        if (user == null || user.token == null || user.token!.isEmpty) {
          if (mounted) {
            setState(() {
              _loading = false;
              _errorMessage = 'bookingLoadError';
            });
          }
          return;
        }

        _role = user.role;
        Booking? found;

        final uid = int.tryParse(user.id);
        if (uid != null) {
          final r = await sl<GetMyBookingsUseCase>()(uid);
          r.fold((_) {}, (list) {
            try {
              found = list.firstWhere((b) => b.id == id);
            } catch (_) {}
          });
        }

        if (found == null && _isCompanyStaff && user.token != null) {
          final payload = JwtClaimsHelper.decodePayload(user.token);
          final companyId = JwtClaimsHelper.companyId(payload);
          if (companyId != null) {
            final r2 = await sl<GetCompanyBookingsUseCase>()(companyId);
            r2.fold((_) {}, (list) {
              try {
                found = list.firstWhere((b) => b.id == id);
              } catch (_) {}
            });
          }
        }

        if (!mounted) return;
        setState(() {
          _booking = found;
          _loading = false;
          if (found == null) {
            _errorMessage = 'bookingNotFound';
          }
        });
        if (found != null) {
          await _loadWorkTypeAndFee(found!);
          if (_isCustomer) {
            await _loadBookingReportsCheck(found!);
          }
          if (_isCustomer &&
              found!.status == BookingStatusCodes.completed) {
            await _loadReviewStatus(found!.id);
          }
        }
      },
    );
  }

  Future<void> _loadWorkTypeAndFee(Booking booking) async {
    final wtResult = await sl<GetWorkerWorkTypesUseCase>()(booking.workerId);
    WorkType? matched;
    wtResult.fold((_) {}, (list) {
      try {
        matched = list.firstWhere((w) => w.id == booking.workerWorkTypeId);
      } catch (_) {
        if (list.isNotEmpty) matched = list.first;
      }
    });

    double fee = 0;
    final companyResult = await sl<GetCompanyByIdUseCase>()(booking.companyId);
    companyResult.fold((_) {}, (company) {
      fee = company.monthlyAccommodationFee ?? 0;
    });
    if (fee <= 0) {
      fee =
          await CompanyMonthlyFeeStore.instance.getFee(
                booking.companyId.toString(),
              ) ??
              0;
    }

    if (mounted) {
      setState(() {
        _workType = matched;
        _monthlyAccommodationFeePerMonth = fee;
      });
    }
  }

  Future<void> _loadReviewStatus(int bookingId) async {
    final has = await _reviewStatusCubit.check(bookingId);
    if (mounted) setState(() => _hasReview = has);
  }

  Future<void> _loadBookingReportsCheck(Booking booking) async {
    if (!_isCustomer) return;
    setState(() => _loadingBookingReports = true);
    final result = await sl<GetBookingReportsByBookingUseCase>()(
      bookingId: booking.id,
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loadingBookingReports = false;
        _hasActiveBookingReport = false;
      }),
      (page) => setState(() {
        _loadingBookingReports = false;
        _hasActiveBookingReport = BookingReportPolicy.hasActiveReport(
          page.items,
        );
      }),
    );
  }

  int _monthCountFromBooking(Booking booking) {
    final start = booking.startDate ?? booking.bookingDate;
    final end = booking.endDate ?? start;
    final days = end.difference(start).inDays + 1;
    if (days <= 0) return 1;
    return (days / 30).ceil();
  }

  String? _shiftHoursLabel(BuildContext context) {
    final wt = _workType;
    if (wt == null) return null;
    final hoursLabel = L10n.of(context)?.translate('hours') ?? 'hours';
    return ShiftHoursFormatter.formatDurationLabel(
      wt.startTime,
      wt.endTime,
      hoursLabel: hoursLabel,
    );
  }

  Future<void> _setStatus(
    int status, {
    String? rejectionReason,
  }) async {
    final booking = _booking;
    if (booking == null || _updating) return;

    setState(() => _updating = true);
    final result = await sl<UpdateBookingStatusUseCase>()(
      booking.id,
      status,
      rejectionReason: rejectionReason,
    );

    if (!mounted) return;
    setState(() => _updating = false);

    result.fold(
      (failure) {
        final l10n = L10n.of(context);
        final message =
            failure is ForbiddenFailure
                ? (l10n?.translate('bookingCompleteForbidden') ??
                    failure.message)
                : failure.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
      (_) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.translate('bookingStatusUpdated') ?? 'Booking updated.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _load();
      },
    );
  }

  Future<void> _confirmCustomerCancel() async {
    final l10n = L10n.of(context);
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(
                  l10n?.translate('bookingConfirmCancelTitle') ??
                      'Cancel this booking?',
                ),
                content: Text(
                  l10n?.translate('bookingConfirmCancelBody') ?? '',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n?.translate('cancel') ?? 'Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n?.translate('confirm') ?? 'Confirm'),
                  ),
                ],
              ),
        ) ??
        false;
    if (ok && mounted) {
      await _setStatus(BookingStatusCodes.canceled);
    }
  }

  Future<void> _promptCompanyReject() async {
    final l10n = L10n.of(context);
    final controller = TextEditingController();
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(l10n?.translate('rejectBooking') ?? 'Reject'),
                content: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText:
                        l10n?.translate('rejectionReasonHint') ?? 'Reason',
                  ),
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n?.translate('cancel') ?? 'Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n?.translate('confirm') ?? 'Confirm'),
                  ),
                ],
              ),
        ) ??
        false;
    if (ok && mounted) {
      final reason = controller.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.of(context)?.translate('rejectionReasonHint') ??
                  'Please enter a rejection reason.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        await _setStatus(
          BookingStatusCodes.rejected,
          rejectionReason: reason,
        );
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final locale = l10n?.locale ?? const Locale('en');

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('bookingSummary') ?? AppStrings.bookingSummary,
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppStrings.routeBookings);
          }
        },
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n?.translate(_errorMessage!) ?? _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
              : _booking == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusSection(context, _booking!, locale),
                    if (_isCustomer &&
                        BookingCustomerStatusDisplay.showCustomerTimeline(
                          _booking!,
                        )) ...[
                      const SizedBox(height: 16),
                      _buildCustomerTimeline(context, _booking!),
                    ],
                    if (_isCustomer) ...[
                      const SizedBox(height: 16),
                      BookingWalletStatusCard(booking: _booking!),
                      if (BookingCustomerStatusDisplay.isCleaningStarted(
                        _booking!,
                      ))
                        _buildCleaningStartedBanner(context),
                    ],
                    if (!_updating &&
                        !BookingStatusCodes.isTerminal(_booking!.status)) ...[
                      const SizedBox(height: 16),
                      if (_isCustomer) _buildCustomerActions(context, _booking!),
                      if (_isCustomer)
                        _buildCustomerReportSection(context, _booking!),
                      if (_isCompanyStaff)
                        _buildCompanyActions(context, _booking!),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      l10n?.translate('bookingSummary') ??
                          AppStrings.bookingSummary,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(context, _booking!, locale),
                    const SizedBox(height: 16),
                    _buildStoredPriceSection(context, _booking!),
                    const SizedBox(height: 24),
                    _buildMaidInfoCard(
                      context,
                      _booking!.workerId.toString(),
                      _booking!.workerName,
                      '',
                      0,
                    ),
                    const SizedBox(height: 24),
                    _buildCompanyInfoCard(
                      context,
                      _booking!.companyId.toString(),
                      _booking!.companyName,
                      '',
                    ),
                    if (_isCustomer &&
                        _booking!.status == BookingStatusCodes.completed) ...[
                      const SizedBox(height: 16),
                      _buildCustomerReviewAction(context, _booking!),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildCustomerActions(BuildContext context, Booking booking) {
    final l10n = L10n.of(context);
    if (booking.status == BookingStatusCodes.pending) {
      return FilledButton.icon(
        onPressed:
            _updating ? null : () => _confirmCustomerCancel(),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.cancel_outlined),
        label: Text(l10n?.translate('cancelBooking') ?? 'Cancel Booking'),
      );
    }
    if (booking.status == BookingStatusCodes.onTheWay &&
        !booking.isWorkerArrivalConfirmed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _updating ? null : _confirmWorkerArrival,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.place_outlined),
            label: Text(
              l10n?.translate('confirmWorkerArrival') ?? 'تأكيد وصول العاملة',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.translate('confirmWorkerArrivalHint') ??
                'عند تأكيد وصول العاملة سيتم بدء الخدمة وخصم قيمة الحجز من المحفظة في حالة الدفع بالمحفظة.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCustomerReportSection(BuildContext context, Booking booking) {
    final l10n = L10n.of(context);
    final canReport =
        BookingReportPolicy.canReportBooking(booking.status) &&
        !_hasActiveBookingReport &&
        !_loadingBookingReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (canReport)
          OutlinedButton.icon(
            onPressed: () async {
              final changed = await context.push<bool>(
                AppStrings.routeCreateBookingReport,
                extra: CreateBookingReportArgs(
                  bookingId: booking.id,
                  bookingLabel: '#${booking.id} — ${booking.companyName}',
                  bookingStatus: booking.status,
                  returnRoute: AppStrings.bookingDetailsRoute(
                    booking.id.toString(),
                  ),
                ),
              );
              if (changed == true && mounted) {
                await _loadBookingReportsCheck(booking);
              }
            },
            icon: const Icon(Icons.report_problem_outlined),
            label: Text(
              l10n?.translate('submitBookingReport') ?? 'تقديم بلاغ',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        TextButton(
          onPressed:
              _loadingBookingReports
                  ? null
                  : () => context.push(
                    AppStrings.bookingReportsByBookingRoute(booking.id),
                  ),
          child: Text(
            l10n?.translate('bookingReportsForBooking') ?? 'بلاغات هذا الحجز',
          ),
        ),
      ],
    );
  }

  Widget _buildCleaningStartedBanner(BuildContext context) {
    final l10n = L10n.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cleaning_services_outlined,
              color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n?.translate('workerArrivalConfirmedAndCleaningStarted') ??
                  'تم تأكيد وصول العاملة وبدأت عملية التنظيف.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTimeline(BuildContext context, Booking booking) {
    final l10n = L10n.of(context);
    final stepLabels = BookingCustomerStatusDisplay.customerTimelineLabelKeys
        .map((key) => l10n?.translate(key) ?? key)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n?.translate('bookingStatus') ?? AppStrings.bookingStatus,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          BookingStatusTimeline(
            activeStepIndex:
                BookingCustomerStatusDisplay.customerTimelineStepIndex(
                  booking,
                ),
            stepLabels: stepLabels,
            inProgressStepIndex:
                BookingCustomerStatusDisplay.cleaningStartedTimelineStep,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmWorkerArrival() async {
    final booking = _booking;
    if (booking == null || _updating) return;

    final l10n = L10n.of(context);
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(
                  l10n?.translate('confirmWorkerArrival') ??
                      'تأكيد وصول العاملة',
                ),
                content: Text(
                  l10n?.translate('confirmWorkerArrivalBody') ??
                      'تأكيد أن العاملة وصلت إلى موقع الخدمة؟',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n?.translate('cancel') ?? 'Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n?.translate('confirm') ?? 'Confirm'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!ok || !mounted) return;

    setState(() => _updating = true);
    final result = await sl<ConfirmWorkerArrivalUseCase>()(booking.id);
    if (!mounted) return;
    setState(() => _updating = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.translate('workerArrivalConfirmedAndCleaningStarted') ??
                  'تم تأكيد وصول العاملة وبدأت عملية التنظيف.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _load();
      },
    );
  }

  Widget _buildCustomerReviewAction(BuildContext context, Booking booking) {
    final l10n = L10n.of(context);
    if (_hasReview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasReview == true) {
      return OutlinedButton.icon(
        onPressed: () async {
          final changed = await context.push<bool>(
            AppStrings.myReviewRoute(booking.id),
          );
          if (changed == true && mounted) {
            await _loadReviewStatus(booking.id);
          }
        },
        icon: const Icon(Icons.rate_review_outlined),
        label: Text(l10n?.translate('viewYourReview') ?? 'عرض تقييمك'),
      );
    }

    return FilledButton.icon(
      onPressed: () async {
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
          setState(() => _hasReview = true);
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.star_rounded),
      label: Text(l10n?.translate('rateWorker') ?? 'قيّم العاملة'),
    );
  }

  Widget _buildCompanyActions(BuildContext context, Booking booking) {
    final l10n = L10n.of(context);
    if (booking.status == BookingStatusCodes.pending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _updating ? null : () => _setStatus(BookingStatusCodes.approved),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n?.translate('approveBooking') ?? 'Approve'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _updating ? null : _promptCompanyReject,
            icon: Icon(Icons.cancel_outlined, color: AppColors.error),
            label: Text(
              l10n?.translate('rejectBooking') ?? 'Reject',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      );
    }
    if (booking.status == BookingStatusCodes.approved) {
      return FilledButton.icon(
        onPressed:
            _updating
                ? null
                : () => _setStatus(BookingStatusCodes.onTheWay),
        icon: const Icon(Icons.directions_car_outlined),
        label: Text(
          l10n?.translate('markMaidOnTheWay') ?? 'Send worker on the way',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusSection(
    BuildContext context,
    Booking booking,
    Locale locale,
  ) {
    final l10n = L10n.of(context);
    final displayKey = BookingCustomerStatusDisplay.displayStatusKey(booking);
    String label;
    Color tone;
    IconData icon;
    switch (displayKey) {
      case 'pending':
        label = l10n?.translate('pending') ?? 'Pending';
        tone = AppColors.warning;
        icon = Icons.pending_outlined;
        break;
      case 'approved':
        label = l10n?.translate('approved') ?? 'Approved';
        tone = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case 'on_the_way':
        label = l10n?.translate('onTheWay') ?? 'On the way';
        tone = AppColors.primary;
        icon = Icons.directions_car_outlined;
        break;
      case 'cleaning_started':
        label = l10n?.translate('cleaningStarted') ?? 'Cleaning Started';
        tone = AppColors.success;
        icon = Icons.cleaning_services_outlined;
        break;
      case 'completed':
        label = l10n?.translate('completed') ?? 'Completed';
        tone = AppColors.textSecondary;
        icon = Icons.done_all;
        break;
      case 'canceled':
        label = l10n?.translate('canceled') ?? 'Canceled';
        tone = AppColors.warning;
        icon = Icons.block;
        break;
      case 'rejected':
        label = l10n?.translate('rejected') ?? 'Rejected';
        tone = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
      default:
        label = displayKey;
        tone = AppColors.textSecondary;
        icon = Icons.info_outline;
    }

    String? subtitle;
    if (booking.status == BookingStatusCodes.pending) {
      subtitle =
          l10n?.translate('waitingForConfirmation') ??
          'Waiting for the company to confirm your booking';
    } else if (booking.status == BookingStatusCodes.approved) {
      subtitle =
          l10n?.translate('bookingApproved') ?? 'Your booking has been approved';
    } else if (booking.status == BookingStatusCodes.onTheWay &&
        !booking.isWorkerArrivalConfirmed) {
      subtitle = l10n?.translate('onTheWay') ?? 'On the way';
    } else if (BookingStatusCodes.isInProgress(booking.status)) {
      subtitle =
          l10n?.translate('bookingInProgressSubtitle') ??
          'Your booking is in progress.';
    }

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tone.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: tone, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.translate('bookingStatus') ??
                              AppStrings.bookingStatus,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: tone,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (booking.status == BookingStatusCodes.rejected &&
                  booking.rejectionReason != null &&
                  booking.rejectionReason!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n?.translate('rejectionReasonLabel') ?? 'Rejection reason',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.rejectionReason!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
        .scale(duration: 280.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildStoredPriceSection(BuildContext context, Booking booking) {
    final l10n = L10n.of(context);
    if (!booking.hasStoredPricing) {
      return Text(
        l10n?.translate('bookingPriceDetailsUnavailable') ??
            'Price details are not available for this booking',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      );
    }

    return BookingPriceBreakdownCard(
      title: l10n?.translate('priceSummary') ?? 'Price summary',
      breakdown: BookingPriceBreakdown(
        servicePrice: booking.servicePrice,
        platformFeeAmount: booking.platformFeeAmount,
        totalPrice: booking.totalPrice,
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Booking booking,
    Locale locale,
  ) {
    final l10n = L10n.of(context);
    final start = booking.startDate ?? booking.bookingDate;
    final end = booking.endDate ?? booking.startDate ?? booking.bookingDate;
    final dateStr = WesternNumerals.normalize(
      DateFormat.yMMMd(locale.toString()).format(start),
    );
    final endStr = WesternNumerals.normalize(
      DateFormat.yMMMd(locale.toString()).format(end),
    );
    final range =
        _dateOnly(start) == _dateOnly(end) ? dateStr : '$dateStr – $endStr';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(
            context,
            l10n?.translate('selectedDate') ?? AppStrings.selectedDate,
            range,
          ),
          const SizedBox(height: 12),
          _row(
            context,
            l10n?.translate('location') ?? 'Location',
            booking.locationName?.isNotEmpty == true
                ? booking.locationName!
                : booking.address,
          ),
          if (booking.lat != null && booking.lng != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(booking.lat!, booking.lng!),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bareq.sitt_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(booking.lat!, booking.lng!),
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (booking.startDateDisplay != null) ...[
            const SizedBox(height: 12),
            _row(
              context,
              l10n?.translate('time') ?? 'Time',
              '${booking.startDateDisplay} - ${booking.endDateDisplay ?? ''}',
            ),
          ],
          if (_workType != null) ...[
            const SizedBox(height: 12),
            _row(
              context,
              l10n?.translate('time') ?? 'Time',
              '${_workType!.startTime} - ${_workType!.endTime}',
            ),
          ],
          if (_shiftHoursLabel(context) != null) ...[
            const SizedBox(height: 12),
            _row(
              context,
              l10n?.translate('shiftWorkingHours') ?? 'Shift working hours',
              _shiftHoursLabel(context)!,
            ),
          ],
          if (_workType != null &&
              _workType!.isMonthly &&
              _monthlyAccommodationFeePerMonth > 0) ...[
            const SizedBox(height: 12),
            _row(
              context,
              l10n?.translate('monthlyAccommodationFee') ??
                  'Monthly accommodation fee',
              '${(_monthlyAccommodationFeePerMonth * _monthCountFromBooking(booking)).toStringAsFixed(0)} ${l10n?.translate('lyd') ?? 'LYD'}',
            ),
          ],
        ],
      ),
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoCard(
    BuildContext context,
    String companyId,
    String companyName,
    String companyPhone,
  ) {
    final l10n = L10n.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                l10n?.translate('companyInformation') ?? 'Company Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business, size: 32, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (companyPhone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              companyPhone,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        () => context.push(
                          AppStrings.companyDetailsRoute(companyId),
                        ),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.visibility,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaidInfoCard(
    BuildContext context,
    String maidId,
    String maidName,
    String maidAvatarUrl,
    double maidRating,
  ) {
    final l10n = L10n.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                l10n?.translate('maidInformation') ?? 'Maid Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child:
                    ImageUtils.isValidImageUrl(maidAvatarUrl)
                        ? ClipOval(
                          child: Image.network(
                            maidAvatarUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Image.asset(
                                  'assets/images/worker_placeholder.png',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                          ),
                        )
                        : Image.asset(
                          'assets/images/worker_placeholder.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maidName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (maidRating > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star, size: 18, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            maidRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        () => context.push(AppStrings.maidDetailsRoute(maidId)),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.visibility,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
