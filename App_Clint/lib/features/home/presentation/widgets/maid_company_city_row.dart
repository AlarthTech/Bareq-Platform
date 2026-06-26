import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/maid.dart';

/// Company city for the worker's employer on list cards.
class MaidCompanyCityRow extends StatelessWidget {
  const MaidCompanyCityRow({
    super.key,
    required this.maid,
    this.compact = false,
  });

  final Maid maid;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final city = maid.companyLocation?.trim();
    if (city == null || city.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: compact ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: compact ? 12 : 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              city,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: compact ? 9 : 11,
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
