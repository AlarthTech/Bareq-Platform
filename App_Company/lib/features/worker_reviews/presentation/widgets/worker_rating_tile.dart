import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/rating_formatter.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/star_rating_display.dart';
import '../../domain/entities/worker_rating_row.dart';

class WorkerRatingTile extends StatelessWidget {
  const WorkerRatingTile({
    super.key,
    required this.row,
    required this.onTap,
  });

  final WorkerRatingRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final worker = row.worker;
    final imageUrl = resolveApiUrl(worker.profileImage);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing12,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.gray100,
                  backgroundImage:
                      imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
                  child: imageUrl == null
                      ? Text(
                          worker.fullName.isNotEmpty
                              ? worker.fullName[0]
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryTeal,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.fullName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker.isAvailable ? 'متاحة' : 'غير متاحة',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: worker.isAvailable
                                  ? AppTheme.successGreen
                                  : AppTheme.gray500,
                            ),
                      ),
                    ],
                  ),
                ),
                if (row.hasReviews)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        RatingFormatter.formatAverage(row.summary!.averageRating),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.gray900,
                            ),
                      ),
                      StarRatingDisplay(
                        rating: row.summary!.averageRating,
                        reviewCount: row.summary!.totalReviews,
                        starSize: 14,
                        compact: true,
                      ),
                    ],
                  )
                else
                  Text(
                    'لا توجد تقييمات',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_left, color: AppTheme.gray400, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
