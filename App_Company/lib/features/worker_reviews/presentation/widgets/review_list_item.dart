import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/star_rating_display.dart';
import '../../domain/entities/review.dart';

class ReviewListItem extends StatelessWidget {
  const ReviewListItem({
    super.key,
    required this.review,
    required this.onTap,
  });

  final Review review;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasComment =
        review.comment != null && review.comment!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: const BorderSide(color: AppTheme.gray100),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StarRatingDisplay(
                    rating: review.rating.toDouble(),
                    showCount: false,
                    starSize: 18,
                    compact: true,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      review.userName ?? 'عميل',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    DateFormatter.formatDisplayDate(review.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                ],
              ),
              if (hasComment) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  review.comment!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray700,
                        height: 1.45,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact rating badge for worker list cards (Flow D).
class WorkerRatingBadge extends StatelessWidget {
  const WorkerRatingBadge({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.onTap,
  });

  final double averageRating;
  final int totalReviews;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.warningAmber.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 16, color: AppTheme.warningAmber),
              const SizedBox(width: 4),
              Text(
                '${averageRating.toStringAsFixed(1)} ($totalReviews)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openWorkerReviews(
  BuildContext context, {
  required int workerId,
  required String workerName,
  String? profileImage,
}) {
  context.push(
    AppRoutes.workerReviews(workerId),
    extra: WorkerReviewsPageArgs(
      workerId: workerId,
      workerName: workerName,
      profileImage: profileImage,
    ),
  );
}

class WorkerReviewsPageArgs {
  const WorkerReviewsPageArgs({
    required this.workerId,
    required this.workerName,
    this.profileImage,
  });

  final int workerId;
  final String workerName;
  final String? profileImage;
}
