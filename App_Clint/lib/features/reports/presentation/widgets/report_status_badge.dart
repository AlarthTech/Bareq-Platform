import 'package:flutter/material.dart';
import '../../domain/entities/report.dart';

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({
    super.key,
    required this.statusName,
    required this.status,
  });

  final String statusName;
  final ReportStatus status;

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

  _BadgeColors _colorsFor(ReportStatus status) {
    return switch (status) {
      ReportStatus.pending => const _BadgeColors(
        Color(0xFFFFFBEB),
        Color(0xFFD97706),
      ),
      ReportStatus.underReview => const _BadgeColors(
        Color(0xFFEFF6FF),
        Color(0xFF2563EB),
      ),
      ReportStatus.resolved => const _BadgeColors(
        Color(0xFFECFDF5),
        Color(0xFF059669),
      ),
      ReportStatus.dismissed => const _BadgeColors(
        Color(0xFFF3F4F6),
        Color(0xFF6B7280),
      ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}
