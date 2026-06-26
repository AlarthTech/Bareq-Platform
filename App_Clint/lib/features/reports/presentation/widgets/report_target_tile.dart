import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/report.dart';
import 'report_status_badge.dart';

class ReportTargetTile extends StatelessWidget {
  const ReportTargetTile({
    super.key,
    required this.report,
    required this.onTap,
  });

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat.yMMMd().add_Hm().format(report.createdAt.toLocal());
    final preview =
        report.description.length > 80
            ? '${report.description.substring(0, 80)}…'
            : report.description;

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
                      report.targetDisplayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  ReportStatusBadge(
                    statusName: report.statusName,
                    status: report.status,
                  ),
                ],
              ),
              if (report.targetTypeName != null) ...[
                const SizedBox(height: 4),
                Text(
                  report.targetTypeName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
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
