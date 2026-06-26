import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        final selected = star <= value;
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: selected ? Colors.amber : AppColors.textSecondary,
            size: size,
          ),
        );
      }),
    );
  }
}
