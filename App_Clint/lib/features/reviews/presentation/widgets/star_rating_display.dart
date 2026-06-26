import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 18,
    this.color,
  });

  final double rating;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final fill = (rating - index).clamp(0.0, 1.0);
        IconData icon;
        if (fill >= 1) {
          icon = Icons.star_rounded;
        } else if (fill >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(
          icon,
          size: size,
          color: fill > 0 ? starColor : AppColors.textSecondary,
        );
      }),
    );
  }
}
