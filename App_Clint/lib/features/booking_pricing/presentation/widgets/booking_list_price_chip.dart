import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/booking_price_formatter.dart';

/// Compact total price for booking list rows.
class BookingListPriceChip extends StatelessWidget {
  const BookingListPriceChip({
    super.key,
    required this.totalPrice,
    required this.hasPricing,
  });

  final double totalPrice;
  final bool hasPricing;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final amount = BookingPriceFormatter.formatTotalOrUnavailable(
      context,
      totalPrice: totalPrice,
      hasPricing: hasPricing,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.translate('totalPrice') ?? 'Total',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
