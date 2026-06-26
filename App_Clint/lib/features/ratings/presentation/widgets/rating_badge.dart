import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/rating_summary.dart';
import '../extensions/rating_formatters.dart';
import 'rating_summary_row.dart';

/// Compact rating for list cards (centered).
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.summary,
    this.compact = true,
    this.dense = false,
  });

  final RatingSummary summary;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasReviews) {
      return Text(
        reviewCountLabel(0, context),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: dense ? 9 : (compact ? 11 : 12),
            ),
        textAlign: TextAlign.center,
        maxLines: dense ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: dense ? 14 : 16,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              dense
                  ? '${summary.averageRating.toStringAsFixed(1)} (${summary.totalReviews})'
                  : '${summary.averageRating.toStringAsFixed(1)} ${reviewCountLabel(summary.totalReviews, context)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: dense ? 9 : 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return RatingSummaryRow(
      summary: summary,
      alignment: MainAxisAlignment.center,
    );
  }
}
