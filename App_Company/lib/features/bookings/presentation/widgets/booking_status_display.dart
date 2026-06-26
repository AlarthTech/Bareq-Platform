import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_entity.dart';

/// Shared status visuals for list cards and detail summary (operational labels).
class BookingStatusVisual {
  const BookingStatusVisual({
    required this.label,
    required this.badgeFill,
    required this.badgeOnFill,
    required this.indicatorBar,
    this.showArrivalConfirmedHint = false,
  });

  final String label;
  final Color badgeFill;
  final Color badgeOnFill;
  final Color indicatorBar;
  final bool showArrivalConfirmedHint;
}

/// Presentation-only status derived from booking (backend status unchanged).
BookingStatusVisual bookingDisplayVisual(BookingEntity booking) {
  if (AppConstants.isCleaningStartedDisplay(
    status: booking.status,
    isWorkerArrivalConfirmed: booking.isWorkerArrivalConfirmed,
  )) {
    return BookingStatusVisual(
      label: AppConstants.statusCleaningStartedText,
      badgeFill: AppTheme.successGreen,
      badgeOnFill: Colors.white,
      indicatorBar: AppTheme.successGreen,
      showArrivalConfirmedHint: true,
    );
  }
  return bookingStatusVisual(booking.status);
}

BookingStatusVisual bookingStatusVisual(int status) {
  switch (status) {
    case AppConstants.statusPending:
      return BookingStatusVisual(
        label: AppConstants.statusPendingText,
        badgeFill: AppTheme.warningAmber,
        badgeOnFill: Colors.white,
        indicatorBar: AppTheme.warningAmber,
      );
    case AppConstants.statusApproved:
      return BookingStatusVisual(
        label: AppConstants.statusApprovedText,
        badgeFill: AppTheme.infoBlue,
        badgeOnFill: Colors.white,
        indicatorBar: AppTheme.infoBlue,
      );
    case AppConstants.statusOnTheWay:
      return BookingStatusVisual(
        label: AppConstants.statusOnTheWayText,
        badgeFill: AppTheme.statusPurple,
        badgeOnFill: Colors.white,
        indicatorBar: AppTheme.statusPurple,
      );
    case AppConstants.statusCompleted:
      return BookingStatusVisual(
        label: AppConstants.statusCompletedText,
        badgeFill: AppTheme.successGreenDark,
        badgeOnFill: Colors.white,
        indicatorBar: AppTheme.successGreenDark,
      );
    case AppConstants.statusCanceled:
      return BookingStatusVisual(
        label: AppConstants.statusCanceledText,
        badgeFill: AppTheme.gray500,
        badgeOnFill: Colors.white,
        indicatorBar: AppTheme.gray400,
      );
    case AppConstants.statusRejected:
      return BookingStatusVisual(
        label: AppConstants.statusRejectedText,
        badgeFill: AppTheme.dangerRed,
        badgeOnFill: Colors.white,
        indicatorBar: AppTheme.dangerRed,
      );
    default:
      return BookingStatusVisual(
        label: '—',
        badgeFill: AppTheme.gray400,
        badgeOnFill: Colors.white,
        indicatorBar: AppTheme.gray300,
      );
  }
}

bool bookingShowsOnTheWayArrivalUi(BookingEntity booking) =>
    booking.status == AppConstants.statusOnTheWay;

bool bookingIsAwaitingArrivalConfirmation(BookingEntity booking) =>
    booking.status == AppConstants.statusOnTheWay &&
    !booking.isWorkerArrivalConfirmed;

bool bookingIsCleaningInProgress(BookingEntity booking) =>
    AppConstants.isCleaningStartedDisplay(
      status: booking.status,
      isWorkerArrivalConfirmed: booking.isWorkerArrivalConfirmed,
    );

class BookingStatusPill extends StatelessWidget {
  const BookingStatusPill({super.key, required this.visual, this.large = false});

  final BookingStatusVisual visual;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (large) {
      return BookingStatusBadgeLarge(visual: visual);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: visual.badgeFill,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        visual.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: visual.badgeOnFill,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

/// Prominent status badge for booking list cards.
class BookingStatusBadgeLarge extends StatelessWidget {
  const BookingStatusBadgeLarge({super.key, required this.visual});

  final BookingStatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: visual.badgeFill,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        boxShadow: [
          BoxShadow(
            color: visual.badgeFill.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        visual.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: visual.badgeOnFill,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
      ),
    );
  }
}

/// Small secondary hint shown on list cards when cleaning has started.
class BookingArrivalConfirmedChip extends StatelessWidget {
  const BookingArrivalConfirmedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.successGreen),
          const SizedBox(width: 4),
          Text(
            'تم تأكيد الوصول',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

/// Information card on booking detail when status is OnTheWay.
class BookingOnTheWayInfoCard extends StatelessWidget {
  const BookingOnTheWayInfoCard({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    if (!bookingShowsOnTheWayArrivalUi(booking)) return const SizedBox.shrink();

    final cleaningStarted = bookingIsCleaningInProgress(booking);
    final message = cleaningStarted
        ? 'تم تأكيد وصول العاملة من قبل العميلة وبدأت الخدمة.'
        : 'في انتظار تأكيد وصول العاملة من العميلة.';

    final (Color bg, Color border, Color iconColor) = cleaningStarted
        ? (
            AppTheme.successGreen.withValues(alpha: 0.08),
            AppTheme.successGreen.withValues(alpha: 0.28),
            AppTheme.successGreen,
          )
        : (
            AppTheme.statusPurple.withValues(alpha: 0.08),
            AppTheme.statusPurple.withValues(alpha: 0.28),
            AppTheme.statusPurple,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            cleaningStarted ? Icons.cleaning_services_rounded : Icons.directions_car_rounded,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray800,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Arrival confirmation details block on booking detail.
class BookingArrivalConfirmationSection extends StatelessWidget {
  const BookingArrivalConfirmationSection({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    if (!bookingIsCleaningInProgress(booking)) return const SizedBox.shrink();

    final confirmedAt = booking.workerArrivalConfirmedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ArrivalDetailRow(
          label: 'تأكيد الوصول',
          value: '✓ تم التأكيد',
          valueColor: AppTheme.successGreen,
          valueWeight: FontWeight.w800,
        ),
        if (confirmedAt != null) ...[
          const SizedBox(height: 14),
          _ArrivalDetailRow(
            label: 'وقت التأكيد',
            value: _formatConfirmedAt(confirmedAt),
          ),
        ],
      ],
    );
  }

  static String _formatConfirmedAt(DateTime dt) {
    return '${DateFormatter.formatDisplayWeekdayCompact(dt)} • '
        '${DateFormatter.formatDisplayTime(dt)}';
  }
}

class _ArrivalDetailRow extends StatelessWidget {
  const _ArrivalDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.gray500,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppTheme.gray900,
                fontWeight: valueWeight ?? FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
