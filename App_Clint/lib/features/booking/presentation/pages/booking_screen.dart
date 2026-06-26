import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bareq_nav_chevron.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/auth/jwt_claims_helper.dart';
import '../../../../core/company/company_monthly_fee_store.dart';
import '../../../../core/utils/shift_hours_formatter.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/domain/usecases/get_company_by_id_usecase.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/clear_user_usecase.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';
import '../../../home/domain/entities/maid.dart';
import '../../../home/domain/usecases/get_available_maids_usecase.dart';
import '../../domain/entities/work_type.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status_codes.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/usecases/get_worker_work_types_usecase.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/failure_ui.dart';
import '../../../home/domain/usecases/get_available_maids_page_usecase.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../../booking_pricing/domain/entities/booking_price_preview_params.dart';
import '../../../booking_pricing/presentation/state/booking_price_preview_cubit.dart';
import '../../../booking_pricing/presentation/state/booking_price_preview_state.dart';
import '../../../booking_pricing/presentation/widgets/booking_price_breakdown_card.dart';
import '../../../booking_pricing/presentation/widgets/booking_price_breakdown_skeleton.dart';
import '../../../../core/utils/booking_price_formatter.dart';
import '../../../user_locations/domain/entities/user_location.dart';
import '../widgets/service_responsibility_notice_card.dart';
import '../../../user_locations/domain/usecases/get_my_locations_usecase.dart';
import '../widgets/custom_calendar.dart';
import '../widgets/booking_success_dialog.dart';
import '../widgets/skeleton/booking_skeleton.dart';
import '../../../wallet/domain/constants/wallet_top_up_methods.dart';
import '../../../wallet/domain/entities/wallet_booking_quote.dart';
import '../../../wallet/domain/entities/wallet_summary.dart';
import '../../../wallet/domain/usecases/get_wallet_booking_quote.dart';
import '../../../wallet/domain/usecases/get_wallet_summary.dart';
import '../../../wallet/presentation/widgets/wallet_booking_payment_section.dart';

/// Booking Screen with step-by-step flow
/// Step 1: Choose booking type (Single Day/Overnight) and reason
/// Step 2: Select date
/// Step 3: Confirm booking
class BookingScreen extends StatefulWidget {
  final String maidId;

  const BookingScreen({super.key, required this.maidId});

  /// Month names in date chips use English (e.g. May) even when UI is Arabic.
  static const String _englishMonthDateLocale = 'en';

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;
  String? _selectedBookingType; // 'single_day', 'overnight', or 'monthly'
  WorkType? _selectedWorkType;
  DateTime? _selectedDate;

  /// First day of the month shown in the monthly booking calendar.
  DateTime _monthlyViewMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  /// Start of the monthly booking window (calendar date).
  DateTime? _monthlyPeriodStart;

  /// Each booked "month" is exactly this many days (pricing / duration).
  static const int _daysPerBookingMonth = 30;

  /// How many such months the user selected (1 month = 30 days).
  int _monthlyMonthCount = 1;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime _focusedDay = DateTime.now();

  int get _monthlyBookingTotalDays => _monthlyMonthCount * _daysPerBookingMonth;
  bool _isInitialLoading = true;
  bool _isLoadingWorkTypes = true;
  bool _isCreatingBooking = false;
  Maid? _maid;
  User? _currentUser;
  List<WorkType> _singleDayWorkTypes = [];
  List<WorkType> _overnightWorkTypes = [];
  List<WorkType> _monthlyWorkTypes = [];
  final Set<int> _bookedDateKeys = <int>{};
  bool _isLoadingBookedDates = false;
  double _monthlyAccommodationFeePerMonth = 0;
  List<UserLocation> _savedLocations = [];
  int? _selectedUserLocationId;
  bool _loadingLocations = false;
  late final BookingPricePreviewCubit _pricePreviewCubit;
  Timer? _previewDebounce;
  bool _bookMonthlyPricing = false;
  bool _acceptedResponsibilityNotice = false;
  bool _showResponsibilityValidation = false;
  WalletSummary? _walletSummary;
  String? _selectedPaymentMethod;

  bool get _isOvernightSelected => _selectedWorkType?.isOvernight ?? false;
  bool get _isMonthlySelected => _selectedWorkType?.isMonthly ?? false;

  int get _numberOfDays {
    if (_fromDate == null || _toDate == null) return 0;
    return _toDate!.difference(_fromDate!).inDays +
        1; // +1 to include both start and end dates
  }

  double get _serviceSubtotal {
    if (_selectedWorkType == null) return 0.0;
    if (_isMonthlySelected) {
      final unit = _selectedWorkType!.monthlyPrice ?? _selectedWorkType!.price;
      return unit * _monthlyMonthCount;
    }
    if (_isOvernightSelected) {
      return _selectedWorkType!.price * _numberOfDays;
    }
    return _selectedWorkType!.price;
  }

  double get _monthlyAccommodationTotal =>
      _isMonthlySelected
          ? _monthlyAccommodationFeePerMonth * _monthlyMonthCount
          : 0;

  double get _totalPrice => _serviceSubtotal + _monthlyAccommodationTotal;

  String? _shiftHoursLabel(BuildContext context, WorkType workType) {
    final hoursLabel = L10n.of(context)?.translate('hours') ?? 'hours';
    return ShiftHoursFormatter.formatDurationLabel(
      workType.startTime,
      workType.endTime,
      hoursLabel: hoursLabel,
    );
  }

  bool get _hasSingleDayOptions => _singleDayWorkTypes.isNotEmpty;
  bool get _hasOvernightOptions => _overnightWorkTypes.isNotEmpty;
  bool get _hasMonthlyOptions => _monthlyWorkTypes.isNotEmpty;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  int _dateKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  bool _isDayBlocked(DateTime day) => _bookedDateKeys.contains(_dateKey(_dateOnly(day)));
  bool _isDaySelectable(DateTime day) => !_isDayBlocked(day);

  /// Inclusive overlap on calendar days between two date ranges.
  bool _dateRangesOverlapInclusive(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    final a0 = _dateOnly(startA.isBefore(endA) ? startA : endA);
    final a1 = _dateOnly(startA.isBefore(endA) ? endA : startA);
    final b0 = _dateOnly(startB.isBefore(endB) ? startB : endB);
    final b1 = _dateOnly(startB.isBefore(endB) ? endB : startB);
    return !a0.isAfter(b1) && !a1.isBefore(b0);
  }

  void _addOccupiedDayRange(Set<int> booked, Booking booking) {
    final start = _dateOnly(booking.startDate ?? booking.bookingDate);
    final end = _dateOnly(booking.endDate ?? booking.startDate ?? booking.bookingDate);
    final from = start.isBefore(end) ? start : end;
    final to = start.isBefore(end) ? end : start;
    for (
      DateTime d = from;
      !d.isAfter(to);
      d = d.add(const Duration(days: 1))
    ) {
      booked.add(_dateKey(d));
    }
  }

  /// Refreshes worker availability for the booking date after a 409 conflict.
  Future<void> _refreshAvailabilityAfterConflict(DateTime date) async {
    try {
      await sl<GetAvailableMaidsPageUseCase>()(
        selectedDate: date,
        page: 1,
        pageSize: 20,
      );
    } catch (_) {}
    await _loadWorkerBookedDates();
  }

  Future<void> _loadWorkerBookedDates() async {
    final workerId = int.tryParse(widget.maidId);
    if (workerId == null) return;
    setState(() => _isLoadingBookedDates = true);
    try {
      int? currentUserId;
      final token = _currentUser?.token;
      if (token != null) {
        final payload = JwtClaimsHelper.decodePayload(token);
        final nameId = JwtClaimsHelper.nameIdentifier(payload);
        currentUserId = int.tryParse(nameId ?? '');
      }

      if (currentUserId != null) {
        final result = await sl<GetMyBookingsUseCase>()(currentUserId);
        final booked = <int>{};
        result.fold((_) {}, (bookings) {
          for (final booking in bookings) {
            if (booking.workerId != workerId) continue;
            if (!BookingStatusCodes.holdsWorkerSlot(booking.status)) continue;
            _addOccupiedDayRange(booked, booking);
          }
        });
        if (!mounted) return;
        setState(() {
          _bookedDateKeys
            ..clear()
            ..addAll(booked);
        });
        return;
      }
      if (!mounted) return;
      setState(() => _bookedDateKeys.clear());
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookedDates = false);
      }
    }
  }

  String _monthDurationPhrase(BuildContext context, int count) {
    final l10n = L10n.of(context);
    final n = WesternNumerals.normalize(count.toString());
    final unit =
        count == 1
            ? (l10n?.translate('monthDurationSingular') ?? 'month')
            : (l10n?.translate('monthDurationPlural') ?? 'months');
    return '$n $unit';
  }

  DateTime? get _monthlyPeriodEnd {
    if (_monthlyPeriodStart == null) return null;
    return _dateOnly(
      _monthlyPeriodStart!,
    ).add(Duration(days: _monthlyBookingTotalDays - 1));
  }

  bool _canGoToPreviousMonthlyMonth() {
    final today = _dateOnly(DateTime.now());
    final prevMonthLastDay = DateTime(
      _monthlyViewMonth.year,
      _monthlyViewMonth.month,
      0,
    );
    return !prevMonthLastDay.isBefore(today);
  }

  bool _canGoToNextMonthlyMonth() {
    final limit = DateTime(DateTime.now().year, DateTime.now().month + 24, 1);
    final next = DateTime(
      _monthlyViewMonth.year,
      _monthlyViewMonth.month + 1,
      1,
    );
    return next.isBefore(limit);
  }

  bool get _canProceedToStep2 {
    return _selectedWorkType != null;
  }

  bool get _canProceedToStep3 {
    if (_isMonthlySelected) {
      return _monthlyPeriodStart != null;
    }
    if (_isOvernightSelected) {
      return _fromDate != null &&
          _toDate != null &&
          (_fromDate!.isBefore(_toDate!) ||
              _fromDate!.isAtSameMomentAs(_toDate!));
    }
    return _selectedDate != null;
  }

  bool get _sendIsMonthly =>
      _isMonthlySelected ||
      (_bookMonthlyPricing &&
          _selectedWorkType?.monthlyPrice != null &&
          (_selectedWorkType!.monthlyPrice ?? 0) > 0);

  bool get _showMonthlyPricingToggle =>
      _selectedWorkType != null &&
      !_isMonthlySelected &&
      _selectedWorkType!.monthlyPrice != null &&
      (_selectedWorkType!.monthlyPrice ?? 0) > 0;

  WalletBookingQuote? get _walletQuote {
    final summary = _walletSummary;
    final preview = _pricePreviewCubit.state;
    if (summary == null || preview is! BookingPricePreviewLoaded) {
      return null;
    }
    return sl<GetWalletBookingQuoteUseCase>()(
      summary: summary,
      bookingTotalPrice: preview.breakdown.totalPrice,
    );
  }

  bool get _isWalletPaymentSelected =>
      _selectedPaymentMethod == WalletTopUpMethods.wallet;

  bool get _canConfirmBooking {
    if (!_canProceedToStep3 ||
        _selectedUserLocationId == null ||
        _pricePreviewCubit.state is! BookingPricePreviewLoaded ||
        !_acceptedResponsibilityNotice) {
      return false;
    }
    if (_isWalletPaymentSelected) {
      final summary = _walletSummary;
      final quote = _walletQuote;
      if (summary == null ||
          quote == null ||
          !summary.isWalletPaymentEnabled ||
          summary.availableBalance < quote.requiredAmount) {
        return false;
      }
    }
    return true;
  }

  Future<void> _loadWalletSummary() async {
    final result = await sl<GetWalletSummaryUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) {},
      (summary) {
        setState(() {
          _walletSummary = summary;
          if (!summary.isWalletPaymentEnabled &&
              _selectedPaymentMethod == WalletTopUpMethods.wallet) {
            _selectedPaymentMethod = null;
          }
        });
      },
    );
  }

  void _onBookingInputsChanged() {
    if (_currentStep == 2) {
      _schedulePricePreview();
    }
  }

  void _schedulePricePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || _currentStep != 2) return;
      final params = _buildPricePreviewParams();
      if (params == null) {
        _pricePreviewCubit.reset();
        return;
      }
      _pricePreviewCubit.loadPreview(params);
    });
  }

  BookingPricePreviewParams? _buildPricePreviewParams() {
    final schedule = _resolveApiSchedule();
    if (schedule == null) return null;

    final companyId = int.tryParse(_maid?.companyId ?? '');
    final workerId = int.tryParse(widget.maidId);
    final workTypeId = _selectedWorkType?.workTypeId;
    if (companyId == null ||
        companyId <= 0 ||
        workerId == null ||
        workTypeId == null) {
      return null;
    }

    return BookingPricePreviewParams(
      companyId: companyId,
      workerId: workerId,
      workTypeId: workTypeId,
      bookingDate: schedule.bookingDate,
      startDate: schedule.apiStart,
      endDate: schedule.apiEnd,
      isMonthly: _sendIsMonthly,
    );
  }

  ({DateTime bookingDate, String apiStart, String apiEnd})? _resolveApiSchedule() {
    if (_selectedWorkType == null) return null;

    late DateTime startDate;
    late DateTime endDate;

    if (_isMonthlySelected) {
      if (_monthlyPeriodStart == null) return null;
      startDate = _dateOnly(_monthlyPeriodStart!);
      endDate = startDate.add(Duration(days: _monthlyBookingTotalDays - 1));
    } else if (_isOvernightSelected) {
      if (_fromDate == null || _toDate == null) return null;
      startDate = _fromDate!;
      endDate = _toDate!;
    } else {
      if (_selectedDate == null) return null;
      startDate = _selectedDate!;
      endDate = _selectedDate!;
    }

    startDate = _dateOnly(startDate);
    endDate = _dateOnly(endDate);

    final singleDayShift = !_isMonthlySelected && !_isOvernightSelected;
    if (singleDayShift) {
      return (
        bookingDate: DateTime(startDate.year, startDate.month, startDate.day),
        apiStart: _selectedWorkType!.startTime,
        apiEnd: _selectedWorkType!.endTime,
      );
    }

    return (
      bookingDate: DateTime.now(),
      apiStart: _formatApiDate(startDate),
      apiEnd: _formatApiDate(endDate),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _selectedWorkType != null) {
        _loadWorkerBookedDates();
      }
      setState(() {
        _currentStep++;
      });
      if (_currentStep == 2) {
        _schedulePricePreview();
        _loadWalletSummary();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        if (_currentStep == 2) {
          _acceptedResponsibilityNotice = false;
          _showResponsibilityValidation = false;
        }
        _currentStep--;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_isCreatingBooking) return;

    if (!_acceptedResponsibilityNotice) {
      setState(() => _showResponsibilityValidation = true);
      _showError(
        L10n.of(context)?.translate('serviceResponsibilityNoticeRequired') ??
            'Please accept the responsibility notice to continue.',
      );
      return;
    }

    // Validate required data
    if (_currentUser == null) {
      _showError('Please log in to create a booking');
      return;
    }

    // JWT sanity check: ensure nameidentifier is present + int.
    // If it's missing/invalid, the server will not be able to resolve the user.
    final token = _currentUser!.token;
    final payload = JwtClaimsHelper.decodePayload(token);
    final nameId = JwtClaimsHelper.nameIdentifier(payload);
    final nameIdInt = int.tryParse(nameId ?? '');
    if (nameIdInt == null) {
      if (mounted) {
        final clearUserUseCase = sl<ClearUserUseCase>();
        await clearUserUseCase();
        _showError('Session invalid. Please login again.');
        if (mounted) {
          context.go(AppStrings.routeLogin);
        }
      }
      return;
    }

    if (_maid == null) {
      _showError('Worker information not found');
      return;
    }

    if (_selectedWorkType == null) {
      _showError('Please select a work type');
      return;
    }

    if (_maid!.companyId == null) {
      _showError('Company information not found');
      return;
    }

    final companyId = int.tryParse(_maid!.companyId!);
    final workerId = int.tryParse(_maid!.id);
    final workTypeId = _selectedWorkType!.workTypeId;

    if (companyId == null || workerId == null) {
      _showError('Invalid booking data');
      return;
    }

    final schedule = _resolveApiSchedule();
    if (schedule == null) {
      _showError('Please complete date and time selection');
      return;
    }

    final startDate = _dateOnly(
      _isMonthlySelected
          ? _monthlyPeriodStart!
          : (_isOvernightSelected ? _fromDate! : _selectedDate!),
    );
    final endDate = _isMonthlySelected
        ? startDate.add(Duration(days: _monthlyBookingTotalDays - 1))
        : _dateOnly(_isOvernightSelected ? _toDate! : _selectedDate!);

    final duplicateCheck = await sl<GetMyBookingsUseCase>()(nameIdInt);
    var abortBooking = false;
    duplicateCheck.fold(
      (failure) {
        abortBooking = true;
        if (mounted) _showError(failure.message);
      },
      (bookings) {
        for (final b in bookings) {
          if (b.workerId != workerId) continue;
          if (BookingStatusCodes.isTerminal(b.status)) continue;
          final bs = _dateOnly(b.startDate ?? b.bookingDate);
          final be = _dateOnly(b.endDate ?? b.startDate ?? b.bookingDate);
          if (_dateRangesOverlapInclusive(startDate, endDate, bs, be)) {
            abortBooking = true;
            if (mounted) {
              final l10n = L10n.of(context);
              _showError(
                l10n?.translate('duplicateBookingSameWorker') ??
                    'You already have a booking with this worker on overlapping dates (including pending approval).',
              );
            }
            return;
          }
        }
      },
    );
    if (abortBooking) return;

    if (_selectedUserLocationId == null) {
      _showError(
        L10n.of(context)?.translate('selectBookingLocation') ??
            'Please select a saved location',
      );
      return;
    }

    final bookingRequest = BookingRequest(
      companyId: companyId,
      workerId: workerId,
      workTypeId: workTypeId,
      bookingDate: schedule.bookingDate,
      startDate: schedule.apiStart,
      endDate: schedule.apiEnd,
      userLocationId: _selectedUserLocationId,
      isMonthly: _sendIsMonthly,
      acceptedResponsibilityNotice: true,
      paymentMethod: _isWalletPaymentSelected
          ? WalletTopUpMethods.wallet
          : null,
    );

    // Print booking JSON to the run terminal for debugging
    final bookingJson = bookingRequest.toJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(bookingJson);
    debugPrint('\n═══════════════════════════════════════════════════════════');
    debugPrint('📋 BOOKING REQUEST JSON (CreateBooking):');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint(jsonString);
    debugPrint('═══════════════════════════════════════════════════════════\n');

    setState(() {
      _isCreatingBooking = true;
    });

    try {
      final createBookingUseCase = sl<CreateBookingUseCase>();
      final result = await createBookingUseCase(bookingRequest);

      result.fold(
        (failure) async {
          if (!mounted) return;
          setState(() => _isCreatingBooking = false);
          if (failureRequiresLogout(failure) ||
              failure.message.contains('المستخدم غير موجود')) {
            await sl<ClearUserUseCase>().call();
            if (mounted) context.go(AppStrings.routeLogin);
            return;
          }
          if (failure is BookingConflictFailure) {
            _showBookingConflict(failure.message);
            await _refreshAvailabilityAfterConflict(schedule.bookingDate);
            return;
          }
          if (failure is WalletDisabledFailure) {
            setState(() => _selectedPaymentMethod = null);
            _showError(failure.message);
            return;
          }
          if (failure is InsufficientWalletBalanceFailure) {
            _showInsufficientWallet(failure);
            return;
          }
          if (failure is ValidationFailure) {
            _showError(failure.message);
            return;
          }
          _showError(failureMessage(context, failure));
        },
        (createdBooking) async {
          // Success (201 + BookingDTO)
          if (!mounted) return;
          if (_isWalletPaymentSelected) {
            await _loadWalletSummary();
          }
          if (!mounted) return;
          setState(() {
            _isCreatingBooking = false;
          });

          if (_isWalletPaymentSelected) {
            final l10n = L10n.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.translate('walletBookingReservedSuccess') ??
                      'تم حجز المبلغ من محفظتك',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (mounted) {
            final l10n = L10n.of(context);
            final locale = l10n?.locale ?? const Locale('en');

            String formattedDate;
            if (_isMonthlySelected &&
                _monthlyPeriodStart != null &&
                _monthlyPeriodEnd != null) {
              final fromFormatted = WesternNumerals.normalize(
                DateFormat.yMMMd(
                  BookingScreen._englishMonthDateLocale,
                ).format(_monthlyPeriodStart!),
              );
              final toFormatted = WesternNumerals.normalize(
                DateFormat.yMMMd(
                  BookingScreen._englishMonthDateLocale,
                ).format(_monthlyPeriodEnd!),
              );
              final daysWord = l10n?.translate('days') ?? 'days';
              final totalDaysStr = WesternNumerals.normalize(
                _monthlyBookingTotalDays.toString(),
              );
              formattedDate =
                  '$fromFormatted – $toFormatted ($totalDaysStr $daysWord)';
            } else if (_isOvernightSelected &&
                _fromDate != null &&
                _toDate != null) {
              final fromFormatted = WesternNumerals.normalize(
                DateFormat.yMMMd(locale.toString()).format(_fromDate!),
              );
              final toFormatted = WesternNumerals.normalize(
                DateFormat.yMMMd(locale.toString()).format(_toDate!),
              );
              formattedDate = '$fromFormatted - $toFormatted';
            } else if (_selectedDate != null) {
              formattedDate = WesternNumerals.normalize(
                DateFormat.yMMMd(locale.toString()).format(_selectedDate!),
              );
            } else {
              formattedDate = '';
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => BookingSuccessDialog(bookingDate: formattedDate),
            ).then((_) {
              if (!mounted) return;
              context.go(AppStrings.routeBookings);
              if (!mounted) return;
              context.push(
                AppStrings.bookingDetailsRoute(createdBooking.id.toString()),
              );
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingBooking = false;
        });
        _showError('An unexpected error occurred: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showInsufficientWallet(InsufficientWalletBalanceFailure failure) {
    if (!mounted) return;
    final l10n = L10n.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.translate('walletInsufficientBalance') ??
              'Insufficient wallet balance.',
        ),
        content: Text(failure.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.translate('cancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(AppStrings.routeWalletTopUp).then((_) {
                if (mounted) _loadWalletSummary();
              });
            },
            child: Text(l10n?.translate('walletTopUpNow') ?? 'Top up now'),
          ),
        ],
      ),
    );
  }

  void _showBookingConflict(String detailMessage) {
    if (!mounted) return;
    final l10n = L10n.of(context);
    final hint = l10n?.translate('bookingConflictHint') ??
        'Try another time, another worker, or another date.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detailMessage,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(hint, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pricePreviewCubit = sl<BookingPricePreviewCubit>();
    _loadWorkTypes();
    _loadMaidAndUser();
    _loadSavedLocations();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _pricePreviewCubit.close();
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    setState(() => _loadingLocations = true);
    final result = await sl<GetMyLocationsUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _savedLocations = [];
        _loadingLocations = false;
      }),
      (list) => setState(() {
        _savedLocations = list;
        _loadingLocations = false;
        if (list.length == 1) {
          _selectedUserLocationId = list.first.id;
        }
      }),
    );
  }

  String _formatApiDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _loadMaidAndUser() async {
    // Load maid data
    try {
      final availableMaids = await sl<GetAvailableMaidsUseCase>()();

      Maid? maid;
      try {
        maid = availableMaids.firstWhere((m) => m.id == widget.maidId);
      } catch (_) {}

      if (mounted && maid != null) {
        setState(() {
          _maid = maid;
        });
        await _loadCompanyMonthlyFee(maid);
      }
    } catch (e) {
      // Handle error silently
    }

    // Load current user
    try {
      final getCurrentUserUseCase = sl<GetCurrentUserUseCase>();
      final result = await getCurrentUserUseCase();
      result.fold((_) => null, (user) {
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadCompanyMonthlyFee(Maid maid) async {
    final companyId = maid.companyId;
    if (companyId == null || companyId.isEmpty) return;

    double fee = 0;
    final companyIdInt = int.tryParse(companyId);
    if (companyIdInt != null) {
      final result = await sl<GetCompanyByIdUseCase>()(companyIdInt);
      result.fold((_) {}, (Company company) {
        fee = company.monthlyAccommodationFee ?? 0;
      });
    }
    if (fee <= 0) {
      fee = await CompanyMonthlyFeeStore.instance.getFee(companyId) ?? 0;
    }
    if (mounted) {
      setState(() => _monthlyAccommodationFeePerMonth = fee);
    }
  }

  Future<void> _loadWorkTypes() async {
    try {
      final workerId = int.tryParse(widget.maidId);
      if (workerId == null) {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
            _isLoadingWorkTypes = false;
          });
        }
        return;
      }

      final getWorkerWorkTypesUseCase = sl<GetWorkerWorkTypesUseCase>();
      final result = await getWorkerWorkTypesUseCase(workerId);

      result.fold(
        (failure) {
          // Handle error - show empty state
          if (mounted) {
            setState(() {
              _isInitialLoading = false;
              _isLoadingWorkTypes = false;
            });
          }
        },
        (workTypes) {
          if (mounted) {
            setState(() {
              _monthlyWorkTypes =
                  workTypes.where((wt) => wt.isMonthly).toList();
              _singleDayWorkTypes =
                  workTypes
                      .where((wt) => !wt.isOvernight && !wt.isMonthly)
                      .toList();
              _overnightWorkTypes =
                  workTypes.where((wt) => wt.isOvernight).toList();
              _isInitialLoading = false;
              _isLoadingWorkTypes = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingWorkTypes = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('bookNow') ?? AppStrings.bookNow,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body:
          _isInitialLoading
              ? const BookingSkeleton()
              : Column(
                children: [
                  // Progress Bar
                  _buildProgressBar().animate().fadeIn(
                    duration: 280.ms,
                    curve: Curves.easeOutCubic,
                  ),

                  // Step Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepContent()
                              .animate(delay: 50.ms)
                              .fadeIn(
                                duration: 280.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                  ),

                  BlocBuilder<BookingPricePreviewCubit, BookingPricePreviewState>(
                    bloc: _pricePreviewCubit,
                    builder: (context, _) {
                      return _buildNavigationButtons()
                          .animate(delay: 100.ms)
                          .fadeIn(
                            duration: 280.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
                ],
              ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? AppColors.primary
                                  : AppColors.border.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < 2)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color:
                              isCompleted
                                  ? AppColors.primary
                                  : isActive
                                  ? AppColors.primary
                                  : AppColors.border.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child:
                            isCompleted
                                ? const Icon(
                                  Icons.check,
                                  size: 8,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final l10n = L10n.of(context);
              String stepContext;
              switch (_currentStep) {
                case 0:
                  stepContext =
                      l10n?.translate('bookingType') ?? AppStrings.bookingType;
                  break;
                case 1:
                  stepContext =
                      l10n?.translate('selectDate') ?? AppStrings.selectDate;
                  break;
                case 2:
                  stepContext =
                      l10n?.translate('bookingSummary') ??
                      AppStrings.bookingSummary;
                  break;
                default:
                  stepContext = '';
              }

              return Text(
                '${l10n?.translate('step') ?? AppStrings.step} ${_currentStep + 1} ${l10n?.translate('of') ?? AppStrings.of} 3 – $stepContext',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500, // Medium for section header
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final l10n = L10n.of(context);
            return Text(
              l10n?.translate('bookingType') ?? AppStrings.bookingType,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Booking Type Selection
        if (_isLoadingWorkTypes)
          const BookingWorkTypesLoadingShimmer()
        else ...[
          if (_hasSingleDayOptions ||
              _hasOvernightOptions ||
              _hasMonthlyOptions) ...[
            Row(
              children: [
                if (_hasSingleDayOptions)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final l10n = L10n.of(context);
                        return _buildBookingTypeCard(
                          title:
                              l10n?.translate('singleDay') ??
                              AppStrings.singleDay,
                          icon: Icons.calendar_today,
                          isSelected: _selectedBookingType == 'single_day',
                          onTap: () {
                            setState(() {
                              _selectedBookingType = 'single_day';
                              _selectedWorkType = null;
                              _selectedDate = null;
                              _monthlyPeriodStart = null;
                              _monthlyMonthCount = 1;
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_hasSingleDayOptions && _hasOvernightOptions)
                  const SizedBox(width: 16),
                if (_hasOvernightOptions)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final l10n = L10n.of(context);
                        return _buildBookingTypeCard(
                          title:
                              l10n?.translate('overnight') ??
                              AppStrings.overnight,
                          icon: Icons.hotel,
                          isSelected: _selectedBookingType == 'overnight',
                          onTap: () {
                            setState(() {
                              _selectedBookingType = 'overnight';
                              _selectedWorkType = null;
                              _selectedDate = null;
                              _monthlyPeriodStart = null;
                              _monthlyMonthCount = 1;
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                if ((_hasSingleDayOptions || _hasOvernightOptions) &&
                    _hasMonthlyOptions)
                  const SizedBox(width: 16),
                if (_hasMonthlyOptions)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final l10n = L10n.of(context);
                        return _buildBookingTypeCard(
                          title: l10n?.translate('monthly') ?? 'Monthly',
                          icon: Icons.calendar_month,
                          isSelected: _selectedBookingType == 'monthly',
                          onTap: () {
                            setState(() {
                              _selectedBookingType = 'monthly';
                              _selectedWorkType = null;
                              _selectedDate = null;
                              _monthlyPeriodStart = null;
                              _monthlyMonthCount = 1;
                              _monthlyViewMonth = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                1,
                              );
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),

            // Show work types list based on selected booking type
            if (_selectedBookingType == 'single_day' &&
                _hasSingleDayOptions) ...[
              const SizedBox(height: 32),
              Builder(
                builder: (context) {
                  final l10n = L10n.of(context);
                  return Text(
                    l10n?.translate('selectWorkType') ?? 'Select Work Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ..._singleDayWorkTypes.map(
                (workType) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkTypeCard(
                    context: context,
                    workType: workType,
                    isSelected: _selectedWorkType?.id == workType.id,
                    onTap: () {
                      setState(() {
                        _selectedWorkType = workType;
                        _bookMonthlyPricing = false;
                      });
                      _loadWorkerBookedDates();
                      _onBookingInputsChanged();
                    },
                  ),
                ),
              ),
              _buildMonthlyPricingToggle(context),
            ] else if (_selectedBookingType == 'overnight' &&
                _hasOvernightOptions) ...[
              const SizedBox(height: 32),
              Builder(
                builder: (context) {
                  final l10n = L10n.of(context);
                  return Text(
                    l10n?.translate('selectWorkType') ?? 'Select Work Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ..._overnightWorkTypes.map(
                (workType) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkTypeCard(
                    context: context,
                    workType: workType,
                    isSelected: _selectedWorkType?.id == workType.id,
                    onTap: () {
                      setState(() {
                        _selectedWorkType = workType;
                        _bookMonthlyPricing = false;
                      });
                      _loadWorkerBookedDates();
                      _onBookingInputsChanged();
                    },
                  ),
                ),
              ),
            ] else if (_selectedBookingType == 'monthly' &&
                _hasMonthlyOptions) ...[
              const SizedBox(height: 32),
              Builder(
                builder: (context) {
                  final l10n = L10n.of(context);
                  return Text(
                    l10n?.translate('selectWorkType') ?? 'Select Work Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ..._monthlyWorkTypes.map(
                (workType) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkTypeCard(
                    context: context,
                    workType: workType,
                    isSelected: _selectedWorkType?.id == workType.id,
                    onTap: () {
                      setState(() {
                        _selectedWorkType = workType;
                        _monthlyPeriodStart = null;
                        _monthlyMonthCount = 1;
                        _monthlyViewMonth = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          1,
                        );
                      });
                      _loadWorkerBookedDates();
                      _onBookingInputsChanged();
                    },
                  ),
                ),
              ),
            ],
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No work types available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildBookingTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : AppColors.border.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTypeCard({
    required BuildContext context,
    required WorkType workType,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : AppColors.border.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workType.workTypeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${workType.startTime} - ${workType.endTime}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  if (_shiftHoursLabel(context, workType) != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _shiftHoursLabel(context, workType)!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    workType.isMonthly
                        ? '${BookingPriceFormatter.formatAmount(context, workType.monthlyPrice ?? workType.price)}${L10n.of(context)?.translate('pricePerMonthSuffix') ?? ' / month'}'
                        : BookingPriceFormatter.formatAmount(
                            context,
                            workType.price,
                          ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    if (_isMonthlySelected) {
      return _buildMonthlySelection();
    }
    if (_isOvernightSelected) {
      return _buildDateRangeSelection();
    } else {
      return _buildSingleDateSelection();
    }
  }

  Widget _buildSingleDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final l10n = L10n.of(context);
            return Text(
              l10n?.translate('selectDate') ?? AppStrings.selectDate,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (_isLoadingBookedDates)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: CustomCalendar(
            selectedDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            onDateSelected: (date) {
              if (_isDayBlocked(date)) return;
              setState(() {
                _selectedDate = date;
                _focusedDay = date;
              });
              _onBookingInputsChanged();
            },
            isDateEnabled: _isDaySelectable,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySelection() {
    return _buildMonthlySelectionContent();
  }

  Widget _buildMonthlySelectionContent() {
    final l10n = L10n.of(context);
    final firstOfMonth = DateTime(
      _monthlyViewMonth.year,
      _monthlyViewMonth.month,
      1,
    );
    final lastOfMonth = DateTime(
      _monthlyViewMonth.year,
      _monthlyViewMonth.month + 1,
      0,
    );
    final today = _dateOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.translate('monthlyBookingSelectStartTitle') ??
              'Choose start date',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.translate('monthlyBookingSelectStartHint') ??
              'Select how many months to book (each month = 30 days), then choose the start day on the calendar.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.translate('monthlyBookingMonthsLabel') ??
                    'How many months',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n?.translate('monthlyBookingMonthsHint') ??
                    'Each month counts as 30 days.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _monthlyMonthCount,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.border.withOpacity(0.5),
                    ),
                  ),
                ),
                items: [
                  for (var n = 1; n <= 12; n++)
                    DropdownMenuItem<int>(
                      value: n,
                      child: Text(_monthDurationPhrase(context, n)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _monthlyMonthCount = v);
                    _onBookingInputsChanged();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (_monthlyPeriodStart != null && _monthlyPeriodEnd != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.translate('monthlyBookingPeriodTitle') ??
                                '30-day booking period',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        WesternNumerals.normalize(
                          '${DateFormat.yMMMd(BookingScreen._englishMonthDateLocale).format(_monthlyPeriodStart!)} '
                          '– ${DateFormat.yMMMd(BookingScreen._englishMonthDateLocale).format(_monthlyPeriodEnd!)} '
                          '(${WesternNumerals.normalize(_monthlyBookingTotalDays.toString())} ${l10n?.translate('days') ?? 'days'})',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const BareqStepChevron(
                      direction: BareqStepDirection.back,
                    ),
                    onPressed:
                        _canGoToPreviousMonthlyMonth()
                            ? () {
                              setState(() {
                                _monthlyViewMonth = DateTime(
                                  _monthlyViewMonth.year,
                                  _monthlyViewMonth.month - 1,
                                  1,
                                );
                              });
                            }
                            : null,
                  ),
                  Text(
                    WesternNumerals.normalize(
                      DateFormat.yMMMM(
                        BookingScreen._englishMonthDateLocale,
                      ).format(firstOfMonth),
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const BareqStepChevron(
                      direction: BareqStepDirection.forward,
                    ),
                    onPressed:
                        _canGoToNextMonthlyMonth()
                            ? () {
                              setState(() {
                                _monthlyViewMonth = DateTime(
                                  _monthlyViewMonth.year,
                                  _monthlyViewMonth.month + 1,
                                  1,
                                );
                              });
                            }
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomCalendar(
                headerVisible: false,
                selectedDate: _monthlyPeriodStart,
                firstDate: firstOfMonth,
                lastDate: lastOfMonth,
                focusedDay: firstOfMonth,
                minimumSelectableDate: today,
                onPageChanged: (focusedDay) {
                  setState(() {
                    _monthlyViewMonth = DateTime(
                      focusedDay.year,
                      focusedDay.month,
                      1,
                    );
                  });
                },
                onDateSelected: (date) {
                  if (_isDayBlocked(date)) return;
                  setState(() {
                    _monthlyPeriodStart = _dateOnly(date);
                  });
                  _onBookingInputsChanged();
                },
                isDateEnabled: _isDaySelectable,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelection() {
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final l10n = L10n.of(context);
            return Text(
              l10n?.translate('selectDateRange') ?? 'Select Date Range',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // From Date Input
        _buildDateInputField(
          label: l10n?.translate('fromDate') ?? 'From Date',
          date: _fromDate,
          onTap:
              () => _showDatePickerDialog(
                context,
                initialDate: _fromDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate:
                    _toDate ?? DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  if (_isDayBlocked(date)) return;
                  setState(() {
                    _fromDate = date;
                    if (_toDate != null && _toDate!.isBefore(date)) {
                      _toDate = null;
                    }
                  });
                  _onBookingInputsChanged();
                },
              ),
        ),
        const SizedBox(height: 16),

        // To Date Input
        _buildDateInputField(
          label: l10n?.translate('toDate') ?? 'To Date',
          date: _toDate,
          onTap:
              () => _showDatePickerDialog(
                context,
                initialDate: _toDate ?? _fromDate ?? DateTime.now(),
                firstDate: _fromDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateSelected: (date) {
                  if (_isDayBlocked(date)) return;
                  setState(() {
                    _toDate = date;
                  });
                  _onBookingInputsChanged();
                },
              ),
        ),
        const SizedBox(height: 24),

        // Days Calculator (Read-only)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n?.translate('numberOfDays') ?? 'Number of Days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${_numberOfDays} ${_numberOfDays == 1 ? (l10n?.translate('day') ?? 'day') : (l10n?.translate('days') ?? 'days')}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateInputField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final l10n = L10n.of(context);
    final locale = l10n?.locale ?? const Locale('en');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? WesternNumerals.normalize(
                          DateFormat.yMMMd(locale.toString()).format(date),
                        )
                        : l10n?.translate('selectDate') ??
                            AppStrings.selectDate,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          date != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const BareqNavChevron(
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePickerDialog(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required Function(DateTime) onDateSelected,
  }) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Date',
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
                  CustomCalendar(
                    selectedDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    focusedDay: initialDate,
                    isDateEnabled: _isDaySelectable,
                    onDateSelected: (date) {
                      onDateSelected(date);
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLocationSelectionSection(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.translate('serviceLocation') ?? 'Service location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (_loadingLocations)
            const LinearProgressIndicator(minHeight: 2)
          else if (_savedLocations.isEmpty)
            Text(
              l10n?.translate('noSavedLocationsBooking') ??
                  'No saved locations. Add one in Profile before booking.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else ...[
            ..._savedLocations.map((loc) {
              return RadioListTile<int>(
                value: loc.id,
                groupValue: _selectedUserLocationId,
                onChanged: (selectedId) {
                  if (selectedId == null) return;
                  setState(() => _selectedUserLocationId = selectedId);
                },
                title: Text(loc.locationName),
                subtitle: Text(
                  '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}',
                ),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
          TextButton.icon(
            onPressed: () async {
              await context.push(AppStrings.routeSavedLocations);
              _loadSavedLocations();
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(l10n?.translate('manageLocations') ?? 'Manage locations'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final l10n = L10n.of(context);
            return Text(
              l10n?.translate('bookingSummary') ?? AppStrings.bookingSummary,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Builder(builder: (context) => _buildLocationSelectionSection(context)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final l10n = L10n.of(context);
                  UserLocation? selectedLoc;
                  if (_selectedUserLocationId != null) {
                    for (final loc in _savedLocations) {
                      if (loc.id == _selectedUserLocationId) {
                        selectedLoc = loc;
                        break;
                      }
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                        context,
                        l10n?.translate('bookingType') ??
                            AppStrings.bookingType,
                        _selectedBookingType == 'single_day'
                            ? (l10n?.translate('singleDay') ??
                                AppStrings.singleDay)
                            : _selectedBookingType == 'monthly'
                            ? (l10n?.translate('monthly') ?? 'Monthly')
                            : (l10n?.translate('overnight') ??
                                AppStrings.overnight),
                      ),
                      if (_selectedWorkType != null) ...[
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n?.translate('workType') ?? 'Work Type',
                          _selectedWorkType!.workTypeName,
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n?.translate('time') ?? 'Time',
                          '${_selectedWorkType!.startTime} - ${_selectedWorkType!.endTime}',
                        ),
                        if (_shiftHoursLabel(
                              context,
                              _selectedWorkType!,
                            ) !=
                            null) ...[
                          const SizedBox(height: 16),
                          _buildSummaryRow(
                            context,
                            l10n?.translate('shiftWorkingHours') ??
                                'Shift working hours',
                            _shiftHoursLabel(context, _selectedWorkType!)!,
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      if (_isMonthlySelected &&
                          _monthlyPeriodStart != null &&
                          _monthlyPeriodEnd != null) ...[
                        _buildSummaryRow(
                          context,
                          l10n?.translate('monthlyBookingMonthsLabel') ??
                              'How many months',
                          _monthDurationPhrase(context, _monthlyMonthCount),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n?.translate('fromDate') ?? 'From',
                          WesternNumerals.normalize(
                            DateFormat.yMMMd(
                              BookingScreen._englishMonthDateLocale,
                            ).format(_monthlyPeriodStart!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n?.translate('toDate') ?? 'To',
                          WesternNumerals.normalize(
                            DateFormat.yMMMd(
                              BookingScreen._englishMonthDateLocale,
                            ).format(_monthlyPeriodEnd!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n?.translate('numberOfDays') ?? 'Number of Days',
                          WesternNumerals.normalize(
                            '${_monthlyBookingTotalDays} ${l10n?.translate('days') ?? 'days'}',
                          ),
                        ),
                      ] else if (_isOvernightSelected &&
                          _fromDate != null &&
                          _toDate != null) ...[
                        _buildSummaryRow(
                          context,
                          l10n?.translate('fromDate') ?? 'From Date',
                          WesternNumerals.normalize(
                            DateFormat.yMMMd(
                              (l10n?.locale ?? const Locale('en')).toString(),
                            ).format(_fromDate!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n?.translate('toDate') ?? 'To Date',
                          WesternNumerals.normalize(
                            DateFormat.yMMMd(
                              (l10n?.locale ?? const Locale('en')).toString(),
                            ).format(_toDate!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n?.translate('numberOfDays') ?? 'Number of Days',
                          '$_numberOfDays ${_numberOfDays == 1 ? (l10n?.translate('day') ?? 'day') : (l10n?.translate('days') ?? 'days')}',
                        ),
                      ] else if (_selectedDate != null) ...[
                        _buildSummaryRow(
                          context,
                          l10n?.translate('selectedDate') ??
                              AppStrings.selectedDate,
                          WesternNumerals.normalize(
                            DateFormat.yMMMd(
                              (l10n?.locale ?? const Locale('en')).toString(),
                            ).format(_selectedDate!),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        context,
                        l10n?.translate('location') ?? 'Location',
                        selectedLoc?.locationName ?? '—',
                      ),
                      const SizedBox(height: 16),
                      _buildPricePreviewSection(context),
                      if (_walletSummary != null) ...[
                        const SizedBox(height: 20),
                        WalletBookingPaymentSection(
                          summary: _walletSummary!,
                          quote: _walletQuote,
                          selectedPaymentMethod: _selectedPaymentMethod,
                          onPaymentMethodChanged: (method) {
                            setState(() => _selectedPaymentMethod = method);
                          },
                          onTopUpPressed: () async {
                            await context.push(AppStrings.routeWalletTopUp);
                            if (mounted) _loadWalletSummary();
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildStep3FooterSection(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3FooterSection(BuildContext context) {
    return BlocBuilder<BookingPricePreviewCubit, BookingPricePreviewState>(
      bloc: _pricePreviewCubit,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ServiceResponsibilityNoticeCard(
              accepted: _acceptedResponsibilityNotice,
              showValidationError: _showResponsibilityValidation,
              embeddedInScroll: true,
              onAcceptedChanged: (value) {
                setState(() {
                  _acceptedResponsibilityNotice = value;
                  if (value) {
                    _showResponsibilityValidation = false;
                  }
                });
              },
            ),
            _buildConfirmRequirementsHint(context),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPricePreviewSection(BuildContext context) {
    final l10n = L10n.of(context);

    return BlocBuilder<BookingPricePreviewCubit, BookingPricePreviewState>(
      bloc: _pricePreviewCubit,
      builder: (context, state) {
        return switch (state) {
          BookingPricePreviewInitial() => const SizedBox.shrink(),
          BookingPricePreviewLoading() =>
            const BookingPriceBreakdownSkeleton(),
          BookingPricePreviewLoaded(:final breakdown) =>
            BookingPriceBreakdownCard(breakdown: breakdown),
          BookingPricePreviewError(:final message) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    final params = _buildPricePreviewParams();
                    if (params != null) {
                      _pricePreviewCubit.loadPreview(params);
                    }
                  },
                  child: Text(
                    l10n?.translate('retryPricePreview') ?? 'Retry',
                  ),
                ),
              ],
            ),
        };
      },
    );
  }

  Widget _buildMonthlyPricingToggle(BuildContext context) {
    if (!_showMonthlyPricingToggle) return const SizedBox.shrink();
    final l10n = L10n.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n?.translate('monthlyBookingToggle') ?? 'Monthly booking',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        value: _bookMonthlyPricing,
        onChanged: (value) {
          setState(() => _bookMonthlyPricing = value);
          _onBookingInputsChanged();
        },
      ),
    );
  }

  Widget _buildConfirmRequirementsHint(BuildContext context) {
    if (_canConfirmBooking) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final previewState = _pricePreviewCubit.state;
    final String message;

    if (!_acceptedResponsibilityNotice) {
      message =
          l10n?.translate('serviceResponsibilityNoticeRequired') ??
          'Please accept the responsibility notice to continue.';
    } else if (_selectedUserLocationId == null) {
      message =
          l10n?.translate('selectBookingLocation') ??
          'Please select a saved location';
    } else if (previewState is BookingPricePreviewLoading ||
        previewState is BookingPricePreviewInitial) {
      message =
          l10n?.translate('loadingPricePreview') ??
          'Loading price summary…';
    } else if (previewState is BookingPricePreviewError) {
      message = previewState.message;
    } else {
      message =
          l10n?.translate('completeBookingDetailsForPrice') ??
          'Complete booking details to see the price';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      final l10n = L10n.of(context);
                      return Text(l10n?.translate('back') ?? AppStrings.back);
                    },
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                  onPressed:
                      _isCreatingBooking
                          ? null
                          : (_currentStep == 2
                              ? (_canConfirmBooking ? _confirmBooking : null)
                              : (_currentStep == 0
                                  ? (_canProceedToStep2 ? _nextStep : null)
                                  : (_canProceedToStep3 ? _nextStep : null))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  disabledBackgroundColor: AppColors.textDisabled,
                ),
                child:
                    _isCreatingBooking
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Builder(
                          builder: (context) {
                            final l10n = L10n.of(context);
                            if (_currentStep == 2) {
                              final state = _pricePreviewCubit.state;
                              if (state is BookingPricePreviewLoaded) {
                                final total = BookingPriceFormatter.formatAmount(
                                  context,
                                  state.breakdown.totalPrice,
                                );
                                final template =
                                    l10n?.translate('confirmBookingWithTotal') ??
                                    'Confirm booking — {total}';
                                return Text(
                                  template.replaceAll('{total}', total),
                                );
                              }
                              return Text(
                                l10n?.translate('confirmBooking') ??
                                    AppStrings.confirmBooking,
                              );
                            }
                            return Text(
                              l10n?.translate('next') ?? AppStrings.next,
                            );
                          },
                        ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}
