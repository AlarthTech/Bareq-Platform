import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/rating_summary.dart';
import '../extensions/rating_formatters.dart';

/// Read-only stars + average + review count (summary endpoints).
class RatingSummaryRow extends StatelessWidget {
  const RatingSummaryRow({
    super.key,
    required this.summary,
    this.starSize = 18,
    this.textStyle,
    this.alignment = MainAxisAlignment.start,
  });

  final RatingSummary summary;
  final double starSize;
  final TextStyle? textStyle;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasReviews) {
      return Text(
        reviewCountLabel(0, context),
        style: textStyle ??
            Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
        textAlign: alignment == MainAxisAlignment.center
            ? TextAlign.center
            : TextAlign.start,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        ...List.generate(5, (index) {
          final rating = summary.averageRating;
          final filled = rating >= index + 1;
          final half = !filled && rating > index && rating < index + 1;
          return Icon(
            filled
                ? Icons.star_rounded
                : (half ? Icons.star_half_rounded : Icons.star_border_rounded),
            color: Colors.amber,
            size: starSize,
          );
        }),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${summary.averageRating.ratingLabel(hasReviews: true)} ${reviewCountLabel(summary.totalReviews, context)}',
            style: textStyle ?? Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
