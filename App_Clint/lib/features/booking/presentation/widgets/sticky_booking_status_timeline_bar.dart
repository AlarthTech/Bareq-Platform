import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status_codes.dart';
import '../utils/booking_customer_status_display.dart';
import 'booking_status_timeline.dart';

/// Pinned above the bottom navigation bar on the home screen.
class StickyBookingStatusTimelineBar extends StatelessWidget {
  const StickyBookingStatusTimelineBar({
    super.key,
    required this.booking,
    this.onTap,
  });

  final Booking booking;
  final VoidCallback? onTap;

  /// Reserve space in scroll views so content is not covered.
  static const double contentHeight = 118;

  @override
  Widget build(BuildContext context) {
    if (!BookingStatusCodes.isOngoing(booking.status)) {
      return const SizedBox.shrink();
    }

    final l10n = L10n.of(context);
    final stepLabels = BookingCustomerStatusDisplay.customerTimelineLabelKeys
        .map((key) => l10n?.translate(key) ?? key)
        .toList();

    return Material(
      elevation: 12,
      shadowColor: AppColors.border.withValues(alpha: 0.35),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.workerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    l10n?.translate('viewBookingDetails') ?? 'View details',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
