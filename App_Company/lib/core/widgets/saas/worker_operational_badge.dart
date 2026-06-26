import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../../features/workers/domain/entities/worker_entity.dart';

enum WorkerOperationalStatus {
  available,
  busy,
  inactive,
  certificateExpired,
}

WorkerOperationalStatus workerOperationalStatus(
  WorkerEntity worker, {
  required bool certificateExpired,
}) {
  if (certificateExpired) return WorkerOperationalStatus.certificateExpired;
  if (!worker.isActive) return WorkerOperationalStatus.inactive;
  if (!worker.isAvailable) return WorkerOperationalStatus.busy;
  return WorkerOperationalStatus.available;
}

class WorkerOperationalBadge extends StatelessWidget {
  const WorkerOperationalBadge({
    super.key,
    required this.worker,
    required this.certificateExpired,
  });

  final WorkerEntity worker;
  final bool certificateExpired;

  @override
  Widget build(BuildContext context) {
    final status = workerOperationalStatus(
      worker,
      certificateExpired: certificateExpired,
    );
    final (String label, Color bg, Color fg) = switch (status) {
      WorkerOperationalStatus.available => (
          'متاحة',
          AppTheme.primaryTeal.withValues(alpha: 0.12),
          AppTheme.primaryTeal,
        ),
      WorkerOperationalStatus.busy => (
          'مشغولة',
          AppTheme.warningAmber.withValues(alpha: 0.14),
          AppTheme.warningAmber,
        ),
      WorkerOperationalStatus.inactive => (
          'غير نشطة',
          AppTheme.gray200,
          AppTheme.gray600,
        ),
      WorkerOperationalStatus.certificateExpired => (
          'شهادة منتهية',
          AppTheme.dangerRed.withValues(alpha: 0.12),
          AppTheme.dangerRed,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
      ),
    );
  }
}
