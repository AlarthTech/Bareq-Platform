import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/booking_price_formatter.dart';
import '../../domain/constants/wallet_top_up_methods.dart';
import '../../domain/entities/wallet_booking_quote.dart';
import '../../domain/entities/wallet_summary.dart';

/// Payment method selector and wallet quote for booking step 3.
class WalletBookingPaymentSection extends StatelessWidget {
  const WalletBookingPaymentSection({
    super.key,
    required this.summary,
    required this.quote,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    this.onTopUpPressed,
  });

  final WalletSummary summary;
  final WalletBookingQuote? quote;
  final String? selectedPaymentMethod;
  final ValueChanged<String?> onPaymentMethodChanged;
  final VoidCallback? onTopUpPressed;

  bool get _walletSelected =>
      selectedPaymentMethod == WalletTopUpMethods.wallet;

  bool get _hasInsufficientBalance {
    if (!_walletSelected || quote == null) return false;
    return summary.availableBalance < quote!.requiredAmount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.translate('paymentMethod') ?? 'طريقة الدفع',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        RadioListTile<String?>(
          value: null,
          groupValue: selectedPaymentMethod,
          onChanged: onPaymentMethodChanged,
          title: Text(
            l10n?.translate('paymentAtService') ?? 'الدفع عند تقديم الخدمة',
          ),
        ),
        if (summary.isWalletPaymentEnabled)
          RadioListTile<String?>(
            value: WalletTopUpMethods.wallet,
            groupValue: selectedPaymentMethod,
            onChanged: onPaymentMethodChanged,
            title: Text(
              l10n?.translate('payWithWallet') ?? 'الدفع بالمحفظة',
            ),
          ),
        if (_walletSelected && quote != null) ...[
          const SizedBox(height: 8),
          _QuoteRow(
            label:
                l10n?.translate('walletAvailableBalance') ?? 'الرصيد المتاح',
            value: BookingPriceFormatter.formatAmount(
              context,
              summary.availableBalance,
            ),
          ),
          if (summary.reservedBalance > 0) ...[
            const SizedBox(height: 6),
            _QuoteRow(
              label: l10n?.translate('walletReservedBalance') ?? 'محجوز',
              value: BookingPriceFormatter.formatAmount(
                context,
                summary.reservedBalance,
              ),
            ),
          ],
          const SizedBox(height: 6),
          _QuoteRow(
            label: l10n?.translate('walletPaymentFee') ?? 'رسوم الدفع بالمحفظة',
            value: BookingPriceFormatter.formatAmount(context, quote!.walletFee),
          ),
          const SizedBox(height: 6),
          _QuoteRow(
            label: l10n?.translate('walletRequiredAmount') ??
                'المبلغ المطلوب من المحفظة',
            value: BookingPriceFormatter.formatAmount(
              context,
              quote!.requiredAmount,
            ),
            emphasized: true,
          ),
          if (_hasInsufficientBalance) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n?.translate('walletInsufficientBalance') ??
                        'رصيد المحفظة غير كافٍ لإتمام الحجز.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onTopUpPressed,
                    child: Text(
                      l10n?.translate('walletTopUpNow') ?? 'شحن الآن',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: emphasized ? FontWeight.w600 : null,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized ? AppColors.primary : AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
