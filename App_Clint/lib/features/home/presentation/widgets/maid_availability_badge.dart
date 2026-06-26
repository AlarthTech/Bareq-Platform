import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../domain/entities/maid.dart';

/// Renders [Maid.availabilityLabel] from the workers API (no client-side availability math).
class WorkerAvailabilityBadge extends StatelessWidget {
  const WorkerAvailabilityBadge({
    super.key,
    required this.maid,
    this.prominent = false,
    this.compact = false,
  });

  final Maid maid;
  /// Green style for the available-workers list; top-rated uses [maid.isAvailableToday].
  final bool prominent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = maid.availabilityLabel?.trim();
    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }

    final isProminent = prominent || maid.isAvailableToday;
    final tone =
        isProminent ? AppColors.success : AppColors.textSecondary;
    final icon = isProminent
        ? Icons.check_circle_outline
        : Icons.event_outlined;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: tone),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              WesternNumerals.normalize(label),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 9 : 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
