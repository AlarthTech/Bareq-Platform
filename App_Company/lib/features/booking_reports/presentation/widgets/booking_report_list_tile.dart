import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_report.dart';
import 'booking_report_status_badge.dart';

class BookingReportListTile extends StatelessWidget {
  const BookingReportListTile({
    super.key,
    required this.report,
    this.onTap,
  });

  final BookingReport report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ??
            () => context.push(AppRoutes.companyBookingReportDetail(report.id)),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.gray200),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'حجز #${report.bookingId}',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.gray900,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BookingReportStatusBadge(
                    status: report.status,
                    statusName: report.statusName,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _MetaRow(label: 'العميل', value: report.customerName),
              if (report.workerName != null && report.workerName!.trim().isNotEmpty)
                _MetaRow(label: 'العاملة', value: report.workerName!),
              const SizedBox(height: 6),
              Text(
                report.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray800,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormatter.formatDisplayWeekdayCompact(report.createdAt),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray500,
                  ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray800,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}
