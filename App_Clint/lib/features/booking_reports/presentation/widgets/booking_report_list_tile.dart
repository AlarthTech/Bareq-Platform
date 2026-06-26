import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/booking_report.dart';
import 'booking_report_status_badge.dart';

class BookingReportListTile extends StatelessWidget {
  const BookingReportListTile({
    super.key,
    required this.report,
    required this.onTap,
  });

  final BookingReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateText =
        DateFormat.yMMMd().add_Hm().format(report.createdAt.toLocal());
    final workerLine =
        report.workerName?.trim().isNotEmpty == true
            ? report.workerName!
            : null;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${report.bookingId}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  BookingReportStatusBadge(
                    statusName: report.statusName,
                    status: report.statusEnum,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                report.companyName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (workerLine != null) ...[
                const SizedBox(height: 2),
                Text(
                  workerLine,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                report.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                dateText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
