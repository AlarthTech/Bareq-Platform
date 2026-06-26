import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/booking_price_formatter.dart';
import '../../domain/entities/booking_price_breakdown.dart';

/// Read-only price summary from API preview or stored booking fields.
class BookingPriceBreakdownCard extends StatelessWidget {
  const BookingPriceBreakdownCard({
    super.key,
    required this.breakdown,
    this.title,
  });

  final BookingPriceBreakdown breakdown;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title ??
                  l10n?.translate('priceSummary') ??
                  'Price summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            _PriceRow(
              label: l10n?.translate('servicePrice') ?? 'Service price',
              amount: breakdown.servicePrice,
            ),
            const SizedBox(height: 8),
            _PriceRow(
              label: l10n?.translate('platformFee') ?? 'Platform fee',
              amount: breakdown.platformFeeAmount,
            ),
            const Divider(height: 24),
            _PriceRow(
              label: l10n?.translate('totalPrice') ?? 'Total',
              amount: breakdown.totalPrice,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: bold ? AppColors.primary : AppColors.textPrimary,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
        Text(
          BookingPriceFormatter.formatAmount(context, amount),
          style: style,
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
