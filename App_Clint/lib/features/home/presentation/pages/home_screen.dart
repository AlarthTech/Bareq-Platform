import 'dart:async';

import 'package:flutter/material.dart';
import '../../../booking/domain/entities/booking_status_codes.dart';
import '../../../booking/presentation/state/booking_realtime_cubit.dart';
import '../../../booking/presentation/widgets/ongoing_booking_home_card.dart';
import '../../../booking/presentation/widgets/sticky_booking_status_timeline_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../domain/entities/maid.dart';
import '../../domain/usecases/get_available_maids_page_usecase.dart';
import '../../domain/usecases/get_top_rated_maids_page_usecase.dart';
import '../../../ratings/domain/entities/rating_summary.dart';
import '../widgets/maid_card.dart';
import '../widgets/skeleton/home_skeleton.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bottom_nav_bar.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../notifications/presentation/state/notifications_cubit.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/utils/coming_soon.dart';
import '../../../../core/widgets/common/app_empty_state.dart';
import '../../../../core/widgets/common/bareq_nav_chevron.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../auth/domain/usecases/get_cities_usecase.dart';
import '../../../booking/domain/usecases/get_ongoing_bookings_usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../widgets/home_city_picker_sheet.dart';
import '../cubit/home_state.dart' show HomeCityFilter;

/// Home Screen - Customer view
/// Main screen displaying available maids, categories, and booking options
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit(
      getAvailableMaidsPageUseCase: sl<GetAvailableMaidsPageUseCase>(),
      getTopRatedMaidsPageUseCase: sl<GetTopRatedMaidsPageUseCase>(),
      getCitiesUseCase: sl<GetCitiesUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      getOngoingBookingsUseCase: sl<GetOngoingBookingsUseCase>(),
      sharedPreferences: sl<SharedPreferences>(),
    )..loadHomeData(selectedDate: DateTime.now());
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final PageController _sliderController = PageController();
  bool _showStickyHeader = false;
  DateTime? _selectedDate;
  User? _currentUser;
  int _currentSlide = 0;
  Timer? _sliderTimer;
  StreamSubscription<BookingRealtimeState>? _bookingRealtimeSubscription;
  static const List<String> _sliderImages = [
    'assets/images/home_slider_1.png',
    'assets/images/home_slider_2.png',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _selectedDate = DateTime.now(); // Default to today
    _startSliderAutoPlay();
    _bookingRealtimeSubscription =
        sl<BookingRealtimeCubit>().stream.listen((realtimeState) {
      final event = realtimeState.latest;
      if (event == null || !mounted) return;
      context.read<HomeCubit>().applyBookingStatusUpdate(
            bookingId: event.bookingId,
            statusCode: event.statusCode,
          );
    });
    // Load user after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUser();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final getCurrentUserUseCase = sl<GetCurrentUserUseCase>();
      final result = await getCurrentUserUseCase();
      result.fold((_) => null, (user) {
        if (mounted) {
          setState(() => _currentUser = user);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _sliderTimer?.cancel();
    _bookingRealtimeSubscription?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  void _startSliderAutoPlay() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_sliderController.hasClients) return;
      final nextPage = (_currentSlide + 1) % _sliderImages.length;
      _sliderController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final scrollThreshold = 200.0;
    final isPastThreshold = currentOffset > scrollThreshold;

    // Fade in when scrolling down past threshold
    // Stay visible when past threshold (regardless of scroll direction)
    // Fade out only when scrolling back up to below threshold
    final shouldShow = isPastThreshold;

    if (shouldShow != _showStickyHeader) {
      setState(() {
        _showStickyHeader = shouldShow;
      });
    }
  }

  void _openSearchWithSelectedDate(BuildContext context) {
    context.go(
      AppStrings.routeSearch,
      extra: <String, dynamic>{'selectedDate': _selectedDate ?? DateTime.now()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        showNotificationBell: true,
        showLeadingIdentity: false,
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const HomeSkeleton();
          }

          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HomeCubit>().loadHomeData(
                            selectedDate: _selectedDate ?? DateTime.now(),
                          );
                    },
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          if (state is HomeLoaded) {
            return _buildHomeContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
    final ongoing = state.ongoingBooking;
    final showStickyTimeline =
        ongoing != null && BookingStatusCodes.isOngoing(ongoing.status);
    final scrollBottomInset =
        showStickyTimeline ? StickyBookingStatusTimelineBar.contentHeight : 0.0;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<HomeCubit>().loadHomeData(
                    selectedDate: _selectedDate,
                  ),
              sl<NotificationsCubit>().refreshFromServer(),
            ]);
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + scrollBottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Header - Fade + slide from top
                  _buildGreetingHeader(context, state)
                      .animate()
                      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                      .slideY(
                        begin: -0.03,
                        end: 0,
                        duration: 280.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 16),
                  // Last Update Time Label
                  _buildLastUpdateLabel(context, state.lastUpdateTime),
                  const SizedBox(height: 16),

                // Unified Hero Card: Search + Date + CTA
                _buildUnifiedHeroCard(context)
                    .animate(delay: 50.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                    .scale(duration: 280.ms, curve: Curves.easeOutCubic),
                if (state.ongoingBooking != null &&
                    BookingStatusCodes.isOngoing(state.ongoingBooking!.status)) ...[
                  const SizedBox(height: 20),
                  OngoingBookingHomeCard(
                    booking: state.ongoingBooking!,
                    onTap: () => context.push(
                      AppStrings.bookingDetailsRoute(
                        state.ongoingBooking!.id.toString(),
                      ),
                    ),
                  )
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 280.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
                const SizedBox(height: 24),

                // Available Today Section
                _buildAvailableTodaySection(
                  context,
                  state,
                  isRefreshing: state.isRefreshingWorkers,
                )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),

                // CTA Section (Ad Banner) - Best placement between content sections
                _buildCTASection(context)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),

                // Top Rated Maids Section
                _buildTopRatedSection(context, state)
                    .animate(delay: 450.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        ),
        // Sticky header that appears when scrolling
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildStickySearchCard(context),
        ),
        if (showStickyTimeline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StickyBookingStatusTimelineBar(
              booking: ongoing,
              onTap: () => context.push(
                AppStrings.bookingDetailsRoute(ongoing.id.toString()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStickySearchCard(BuildContext context) {
    // Always render but control opacity - allows smooth fade animation
    return IgnorePointer(
      ignoring: !_showStickyHeader, // Disable interactions when hidden
      child: AnimatedOpacity(
        opacity: _showStickyHeader ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary, // Primary color background
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Soft rounded pill date selector
                  GestureDetector(
                    onTap: () => _showDatePickerDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getDateText(context),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Primary CTA
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openSearchWithSelectedDate(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Builder(
                        builder: (context) {
                          final l10n = L10n.of(context);
                          return Text(
                            l10n?.translate('findAvailableMaids') ??
                                AppStrings.findAvailableMaids,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get display name for the user
  /// Prioritizes fullName, falls back to username
  String _getDisplayName() {
    if (_currentUser == null) {
      return 'User Name'; // Fallback if no user
    }

    // Prioritize fullName if available and not empty
    if (_currentUser!.fullName != null &&
        _currentUser!.fullName!.trim().isNotEmpty) {
      return _currentUser!.fullName!.trim();
    }

    // Fall back to username if available
    if (_currentUser!.username.trim().isNotEmpty) {
      return _currentUser!.username.trim();
    }

    // Default fallback
    return 'User Name';
  }

  String _formatLastUpdateTime(BuildContext context, DateTime lastUpdateTime) {
    final l10n = L10n.of(context);
    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);

    if (difference.inSeconds < 60) {
      return l10n?.translate('lastUpdated') ?? 'Last updated';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      final lastUpdated = l10n?.translate('lastUpdated') ?? 'Last updated';
      final minutesAgo = l10n?.translate('minutesAgo') ?? 'minutes ago';
      return '$lastUpdated $minutes $minutesAgo';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      final lastUpdated = l10n?.translate('lastUpdated') ?? 'Last updated';
      final hoursAgo = l10n?.translate('hoursAgo') ?? 'hours ago';
      return '$lastUpdated $hours $hoursAgo';
    } else {
      final dateFormat = DateFormat(
        'MMM d, h:mm a',
        Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en',
      );
      final lastUpdated = l10n?.translate('lastUpdated') ?? 'Last updated';
      return '$lastUpdated ${WesternNumerals.normalize(dateFormat.format(lastUpdateTime))}';
    }
  }

  Widget _buildLastUpdateLabel(BuildContext context, DateTime lastUpdateTime) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              size: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              _formatLastUpdateTime(context, lastUpdateTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCityPicker(BuildContext context, HomeLoaded state) {
    if (state.cities.isEmpty) return;
    HomeCityPickerSheet.show(
      context: context,
      cities: state.cities,
      selectedCity: state.selectedCity,
      onCitySelected: (city) {
        context.read<HomeCubit>().selectCity(city);
      },
    );
  }

  Widget _buildGreetingHeader(BuildContext context, HomeLoaded state) {
    final l10n = L10n.of(context);
    final cityLabel = state.selectedCity == null
        ? (l10n?.translate('allCities') ?? HomeCityFilter.allCitiesLabel)
        : state.selectedCity!.name;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientTop, // #FFF7F5
            AppColors.gradientBottom, // #FFFFFF
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.translate('goodMorning') ?? AppStrings.goodMorning,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          // User name - increased weight for emotional anchor
          Text(
            _getDisplayName(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700, // Increased from bold to w700
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openCityPicker(context, state),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        cityLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPromoSlider(),
        ],
      ),
    );
  }

  Widget _buildPromoSlider() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: PageView.builder(
              controller: _sliderController,
              itemCount: _sliderImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _sliderImages[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_sliderImages.length, (index) {
            final isActive = index == _currentSlide;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 18 : 6,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUnifiedHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedSearchBar(
            onTap: () {
              _openSearchWithSelectedDate(context);
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showDatePickerDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getDateText(context),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BreathingCTAButton(
                  onPressed: () {
                    _openSearchWithSelectedDate(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDateText(BuildContext context) {
    final l10n = L10n.of(context);
    if (_selectedDate == null) {
      return l10n?.translate('today') ?? AppStrings.today;
    }

    // Always show the selected date, not "اليوم" or "Today"
    final dateFormat = DateFormat(
      'MMM d',
      Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en',
    );
    return WesternNumerals.normalize(dateFormat.format(_selectedDate!));
  }

  void _showDatePickerDialog(BuildContext context) {
    final l10n = L10n.of(context);
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(
      const Duration(days: 365),
    ); // Allow selection up to 1 year ahead

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.translate('selectDate') ?? AppStrings.selectDate,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Calendar
                  TableCalendar(
                    firstDay: firstDate,
                    lastDay: lastDate,
                    focusedDay: _selectedDate ?? now,
                    selectedDayPredicate: (day) {
                      return _selectedDate != null &&
                          isSameDay(_selectedDate, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                      });
                      Navigator.of(dialogContext).pop();
                      // Reload to filter maids by selected date and bookings
                      context.read<HomeCubit>().loadHomeData(
                            selectedDate: selectedDay,
                            reloadTopRated: false,
                          );
                    },
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                      weekendTextStyle: TextStyle(color: AppColors.textPrimary),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      todayTextStyle: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      disabledTextStyle: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      outsideTextStyle: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextFormatter: (date, locale) {
                        return WesternNumerals.normalize(
                          DateFormat.yMMMM(locale).format(date),
                        );
                      },
                      titleTextStyle: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      leftChevronIcon: const BareqStepChevron(
                        direction: BareqStepDirection.back,
                        color: AppColors.primary,
                      ),
                      rightChevronIcon: const BareqStepChevron(
                        direction: BareqStepDirection.forward,
                        color: AppColors.primary,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildWorkersListLoader({double height = 240}) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildAvailableTodaySection(
    BuildContext context,
    HomeLoaded state, {
    bool isRefreshing = false,
  }) {
    final filteredMaids = state.filteredAvailableMaids;
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider before section
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.border.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: AppColors.success.withOpacity(0.8),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _selectedDate != null
                                    ? _getDateText(context)
                                    : (l10n?.translate('availableToday') ??
                                        AppStrings.availableToday),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.translate('availableTodaySubtitle') ??
                              'Services that can be booked immediately',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filteredMaids.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        context.push(
                          AppStrings.routeSearch,
                          extra: {'selectedDate': _selectedDate},
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(44, 36),
                      ),
                      child: Text(
                        l10n?.translate('viewAll') ?? AppStrings.viewAll,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isRefreshing && filteredMaids.isEmpty)
          _buildWorkersListLoader()
        else if (filteredMaids.isEmpty)
          _buildNoMaidsInCityMessage(context)
        else
          SizedBox(
            height: 206,
            child: Stack(
              children: [
                Opacity(
                  opacity: isRefreshing ? 0.45 : 1,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 48) {
                        context.read<HomeCubit>().loadMoreAvailableMaids();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredMaids.length +
                          (state.isLoadingMoreAvailable ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredMaids.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          );
                        }
                        return MaidCard(
                          maid: filteredMaids[index],
                          prominentAvailabilityBadge: true,
                          onTap: isRefreshing
                              ? null
                              : () {
                                  context.go(
                                    AppStrings.maidDetailsRoute(
                                      filteredMaids[index].id,
                                    ),
                                  );
                                },
                        );
                      },
                    ),
                  ),
                ),
                if (isRefreshing)
                  const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoMaidsInCityMessage(BuildContext context) {
    final l10n = L10n.of(context);
    return AppEmptyState(
      icon: Icons.person_search_outlined,
      title: l10n?.translate('noMaidsInSelectedCity') ??
          'No maids in this city for the selected date.',
      subtitle: l10n?.translate('tryAnotherCityOrDate') ??
          'Try another city or pick a different date.',
      actionLabel: l10n?.translate('search') ?? AppStrings.search,
      onAction: () {
        context.push(
          AppStrings.routeSearch,
          extra: {'selectedDate': _selectedDate},
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      iconSize: 48,
    );
  }

  Widget _buildTopRatedSection(BuildContext context, HomeLoaded state) {
    final topRatedMaids = state.filteredTopRatedMaids;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(
              0.05,
            ), // Subtle purple background tint
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 20,
                            color: AppColors.accent,
                          ).animate().fadeIn(
                            duration: 280.ms,
                            curve: Curves.easeOutCubic,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Builder(
                              builder: (context) {
                                final l10n = L10n.of(context);
                                return Text(
                                  l10n?.translate('topRatedMaids') ??
                                      AppStrings.topRatedMaids,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            )
                                .animate(delay: 80.ms)
                                .fadeIn(
                                  duration: 280.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (topRatedMaids.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          context.push(
                            AppStrings.routeSearch,
                            extra: const {
                              'initialMinRating': 4.0,
                            },
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(44, 36),
                        ),
                        child: Builder(
                          builder: (context) {
                            final l10n = L10n.of(context);
                            return Text(
                              l10n?.translate('viewAll') ?? AppStrings.viewAll,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (topRatedMaids.isEmpty)
          _buildNoMaidsInCityMessage(context)
        else
          SizedBox(
            height: 206,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 48) {
                  context.read<HomeCubit>().loadMoreTopRatedMaids();
                }
                return false;
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topRatedMaids.length +
                    (state.isLoadingMoreTopRated ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= topRatedMaids.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  final maid = topRatedMaids[index];
                  final workerId = int.tryParse(maid.id);
                  return MaidCard(
                    maid: maid,
                    emphasizeRating: true,
                    prominentAvailabilityBadge: false,
                    showRatingFromSummary: workerId != null,
                    workerRatingSummary: workerId == null
                        ? null
                        : WorkerRatingSummary(
                            workerId: workerId,
                            averageRating: maid.rating,
                            totalReviews: maid.reviewCount,
                          ),
                    onTap: () {
                      context.go(
                        AppStrings.maidDetailsRoute(
                          topRatedMaids[index].id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.primaryLight.withOpacity(
              0.25,
            ), // Further reduced gradient intensity
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sponsored label
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                l10n?.translate('sponsored') ?? AppStrings.sponsored,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.translate('companyJoinSitt') ??
                          AppStrings.companyJoinSitt,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary, // Increased contrast
                        fontWeight:
                            FontWeight.w700, // Bolder for better contrast
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.translate('manageYourMaidsAndBookings') ??
                          'Manage your maids and bookings',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withOpacity(
                          0.9,
                        ), // Increased contrast (from default ~0.7)
                        fontWeight:
                            FontWeight
                                .w500, // Slightly bolder for better readability
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AnimatedJoinButton(
                onPressed: () {
                  showComingSoonSnackBar(
                    context,
                    messageKey: 'companyRegistrationComingSoon',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated Search Bar with tap feedback
class _AnimatedSearchBar extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedSearchBar({required this.onTap});

  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _glowAnimation;
  late AnimationController _placeholderController;
  int _currentPlaceholderIndex = 0;
  late List<String> _placeholderKeys;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _borderColorAnimation = ColorTween(
      begin: AppColors.border.withOpacity(0.5),
      end: AppColors.primary,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Dynamic placeholder animation
    _placeholderKeys = [
      'searchPlaceholderToday',
      'searchPlaceholderServices',
      'searchPlaceholderLanguage',
      'searchPlaceholder',
    ];
    _placeholderController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _placeholderController.addListener(() {
      if (_placeholderController.value >= 1.0) {
        setState(() {
          _currentPlaceholderIndex =
              (_currentPlaceholderIndex + 1) % _placeholderKeys.length;
        });
        _placeholderController.reset();
        _placeholderController.forward();
      }
    });
    _placeholderController.forward();
  }

  @override
  void dispose() {
    _placeholderController.stop(); // Stop the repeating animation
    _placeholderController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _borderColorAnimation.value ??
                    AppColors.border.withOpacity(0.5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(_glowAnimation.value),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final l10n = L10n.of(context);
                      final placeholderKey =
                          _placeholderKeys[_currentPlaceholderIndex];
                      String placeholder;
                      switch (placeholderKey) {
                        case 'searchPlaceholderToday':
                          placeholder =
                              l10n?.translate('searchPlaceholderToday') ??
                              'Search for maid available today';
                          break;
                        case 'searchPlaceholderServices':
                          placeholder =
                              l10n?.translate('searchPlaceholderServices') ??
                              'Cleaning, weekly, company…';
                          break;
                        case 'searchPlaceholderLanguage':
                          placeholder =
                              l10n?.translate('searchPlaceholderLanguage') ??
                              'Maid who speaks Arabic';
                          break;
                        default:
                          placeholder =
                              l10n?.translate('searchPlaceholder') ??
                              AppStrings.searchPlaceholder;
                      }
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          placeholder,
                          key: ValueKey(placeholderKey),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Breathing CTA Button - subtle scale animation when idle
class _BreathingCTAButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _BreathingCTAButton({required this.onPressed});

  @override
  State<_BreathingCTAButton> createState() => _BreathingCTAButtonState();
}

class _BreathingCTAButtonState extends State<_BreathingCTAButton>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _tapController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    // Breathing animation - every 6-8 seconds
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3), // Half cycle (1 -> 1.01 -> 1)
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Tap animation
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _tapAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );

    // Start breathing after initial delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startBreathing();
      }
    });
  }

  void _startBreathing() {
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapController.forward().then((_) {
      _tapController.reverse();
    });
    // Haptic feedback would go here
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingAnimation, _tapAnimation]),
      builder: (context, child) {
        final scale = _breathingAnimation.value * _tapAnimation.value;
        return Transform.scale(
          scale: scale,
          child: ElevatedButton.icon(
            onPressed: _handleTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.search, size: 20, color: Colors.white),
            label: Builder(
              builder: (context) {
                final l10n = L10n.of(context);
                return Text(
                  l10n?.translate('findAvailableMaids') ??
                      AppStrings.findAvailableMaids,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Staggered slide up animation for maid cards
class _StaggeredSlideUpWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _StaggeredSlideUpWidget({required this.child, required this.delay});

  @override
  State<_StaggeredSlideUpWidget> createState() =>
      _StaggeredSlideUpWidgetState();
}

class _StaggeredSlideUpWidgetState extends State<_StaggeredSlideUpWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.01), // 8px equivalent
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

/// Animated Join Button with scale down on press
class _AnimatedJoinButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedJoinButton({required this.onPressed});

  @override
  State<_AnimatedJoinButton> createState() => _AnimatedJoinButtonState();
}

class _AnimatedJoinButtonState extends State<_AnimatedJoinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _colorAnimation = ColorTween(
      begin: AppColors.primary,
      end: AppColors.primaryDark,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    // Haptic feedback would go here
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: _handleTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorAnimation.value,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Builder(
              builder: (context) {
                final l10n = L10n.of(context);
                return Text(
                  l10n?.translate('join') ?? AppStrings.join,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
