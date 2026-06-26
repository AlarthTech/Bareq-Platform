import 'package:flutter/widgets.dart';

import '../localization/l10n_helper.dart';
import '../utils/western_numerals.dart';

/// Formats server-provided booking amounts (never computes totals).
class BookingPriceFormatter {
  BookingPriceFormatter._();

  static String formatAmount(BuildContext context, double amount) {
    final l10n = L10n.of(context);
    final currency = l10n?.translate('lyd') ?? 'د.ل';
    final value = WesternNumerals.normalize(amount.toStringAsFixed(2));
    return '$value $currency';
  }

  static String formatTotalOrUnavailable(
    BuildContext context, {
    required double totalPrice,
    required bool hasPricing,
  }) {
    if (!hasPricing) {
      return L10n.of(context)?.translate('priceUnavailable') ?? '—';
    }
    return formatAmount(context, totalPrice);
  }
}
