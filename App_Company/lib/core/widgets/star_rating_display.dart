import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/rating_formatter.dart';

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.showCount = true,
    this.starSize = 16,
    this.ratingTextStyle,
    this.compact = false,
  });

  final double rating;
  final int reviewCount;
  final bool showCount;
  final double starSize;
  final TextStyle? ratingTextStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(0.0, 5.0);
    final fullStars = clamped.floor();
    final hasHalf = (clamped - fullStars) >= 0.25 && (clamped - fullStars) < 0.75;
    final roundUp = (clamped - fullStars) >= 0.75;
    final displayFull = roundUp ? fullStars + 1 : fullStars;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text(
            RatingFormatter.formatAverage(clamped),
            style: ratingTextStyle ??
                Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900,
                    ),
          ),
          const SizedBox(width: 4),
        ],
        ...List.generate(5, (index) {
          IconData icon;
          Color color;
          if (index < displayFull) {
            icon = Icons.star_rounded;
            color = AppTheme.warningAmber;
          } else if (index == displayFull && hasHalf) {
            icon = Icons.star_half_rounded;
            color = AppTheme.warningAmber;
          } else {
            icon = Icons.star_outline_rounded;
            color = AppTheme.gray300;
          }
          return Icon(icon, size: starSize, color: color);
        }),
        if (showCount && reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}
