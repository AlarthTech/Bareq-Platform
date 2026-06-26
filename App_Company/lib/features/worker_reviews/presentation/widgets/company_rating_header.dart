import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/rating_formatter.dart';
import '../../../../core/widgets/star_rating_display.dart';
import '../../domain/entities/company_rating_summary.dart';

class CompanyRatingHeader extends StatelessWidget {
  const CompanyRatingHeader({super.key, required this.summary});

  final CompanyRatingSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasReviews) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(Icons.star_outline_rounded, size: 48, color: AppTheme.gray400),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'لا توجد تقييمات بعد',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر تقييمات العملاء هنا بعد إكمال الحجوزات',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray500,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryTeal.withValues(alpha: 0.12),
            AppTheme.warningAmber.withValues(alpha: 0.08),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Text(
            RatingFormatter.formatAverage(summary.averageRating),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gray900,
                  height: 1,
                ),
          ),
          const SizedBox(height: 8),
          StarRatingDisplay(
            rating: summary.averageRating,
            reviewCount: summary.totalReviews,
            showCount: false,
            starSize: 22,
            compact: true,
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            '${summary.totalReviews} تقييم · '
            '${summary.ratedWorkersCount} عاملات مُقيّمة من ${summary.totalActiveWorkers}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray700,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
