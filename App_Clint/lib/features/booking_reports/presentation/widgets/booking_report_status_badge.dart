import 'package:flutter/material.dart';

import '../../domain/entities/booking_report.dart';

class BookingReportStatusBadge extends StatelessWidget {
  const BookingReportStatusBadge({
    super.key,
    required this.statusName,
    required this.status,
  });

  final String statusName;
  final BookingReportStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.35)),
      ),
      child: Text(
        statusName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  _BadgeColors _colorsFor(BookingReportStatus status) {
    return switch (status) {
      BookingReportStatus.open => const _BadgeColors(
        Color(0xFFFFF7ED),
        Color(0xFFEA580C),
      ),
      BookingReportStatus.inReview => const _BadgeColors(
        Color(0xFFEFF6FF),
        Color(0xFF2563EB),
      ),
      BookingReportStatus.resolved => const _BadgeColors(
        Color(0xFFECFDF5),
        Color(0xFF059669),
      ),
      BookingReportStatus.rejected => const _BadgeColors(
        Color(0xFFFEF2F2),
        Color(0xFFDC2626),
      ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}
