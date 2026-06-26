import 'package:flutter/material.dart';

import '../../../../core/localization/l10n_helper.dart';

String reviewCountLabel(int count, BuildContext context) {
  final locale = L10n.of(context)?.locale.languageCode ?? 'ar';
  if (count == 0) {
    return locale == 'ar' ? 'لا توجد تقييمات' : 'No reviews';
  }
  if (locale == 'ar') {
    return count == 1 ? '(تقييم واحد)' : '($count تقييم)';
  }
  return count == 1 ? '(1 review)' : '($count reviews)';
}

extension RatingFormatters on double {
  String ratingLabel({required bool hasReviews}) =>
      hasReviews ? toStringAsFixed(1) : '—';
}
