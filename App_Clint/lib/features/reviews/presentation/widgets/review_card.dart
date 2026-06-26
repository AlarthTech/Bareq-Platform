import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../domain/entities/review.dart';
import 'star_rating_display.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final locale = l10n?.locale ?? const Locale('ar');
    final dateText = WesternNumerals.normalize(
      DateFormat.yMMMd(locale.toString()).format(review.createdAt),
    );
    final userLabel =
        review.userName?.trim().isNotEmpty == true
            ? review.userName!
            : (l10n?.translate('customerLabel') ?? 'عميل');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StarRatingDisplay(rating: review.rating.toDouble()),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (review.comment?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              '"${review.comment!.trim()}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            dateText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
