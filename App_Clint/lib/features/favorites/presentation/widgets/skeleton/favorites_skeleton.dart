import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../../core/constants/app_colors.dart';

/// Skeleton loading widget for favorites screen (matches grid [MaidCard] layout).
class FavoritesSkeleton extends StatelessWidget {
  const FavoritesSkeleton({super.key});

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.12,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: _gridDelegate,
      itemCount: 6,
      itemBuilder: (context, index) => const _FavoriteCardSkeleton(),
    );
  }
}

class _FavoriteCardSkeleton extends StatelessWidget {
  const _FavoriteCardSkeleton();

  Color get _blockColor => AppColors.border.withValues(alpha: 0.3);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border.withValues(alpha: 0.3),
      highlightColor: AppColors.border.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _blockColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: _blockColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 88,
              height: 18,
              decoration: BoxDecoration(
                color: _blockColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 1),
            Container(
              width: 52,
              height: 12,
              decoration: BoxDecoration(
                color: _blockColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
