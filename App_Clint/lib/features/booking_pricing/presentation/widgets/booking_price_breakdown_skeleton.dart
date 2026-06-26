import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class BookingPriceBreakdownSkeleton extends StatelessWidget {
  const BookingPriceBreakdownSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _line(widthFactor: 0.35),
            const SizedBox(height: 16),
            _line(),
            const SizedBox(height: 10),
            _line(),
            const SizedBox(height: 10),
            _line(widthFactor: 0.5),
          ],
        ),
      ),
    );
  }

  Widget _line({double widthFactor = 1}) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
