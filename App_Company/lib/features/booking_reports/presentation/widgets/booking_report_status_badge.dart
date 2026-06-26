import 'package:flutter/material.dart';

import '../../../../core/constants/booking_report_constants.dart';
import '../../../../core/theme/app_theme.dart';

class BookingReportStatusBadge extends StatelessWidget {
  const BookingReportStatusBadge({
    super.key,
    required this.status,
    this.statusName,
  });

  final int status;
  final String? statusName;

  @override
  Widget build(BuildContext context) {
    final (Color fill, String label) = _visualFor(status, statusName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
      ),
    );
  }

  (Color, String) _visualFor(int status, String? statusName) {
    final label = statusName?.trim().isNotEmpty == true
        ? statusName!.trim()
        : switch (status) {
            BookingReportStatus.open => BookingReportStatus.openLabel,
            BookingReportStatus.inReview => BookingReportStatus.inReviewLabel,
            BookingReportStatus.resolved => BookingReportStatus.resolvedLabel,
            BookingReportStatus.rejected => BookingReportStatus.rejectedLabel,
            _ => '—',
          };

    final color = switch (status) {
      BookingReportStatus.open => AppTheme.warningAmber,
      BookingReportStatus.inReview => AppTheme.infoBlue,
      BookingReportStatus.resolved => AppTheme.successGreen,
      BookingReportStatus.rejected => AppTheme.dangerRed,
      _ => AppTheme.gray500,
    };

    return (color, label);
  }
}
