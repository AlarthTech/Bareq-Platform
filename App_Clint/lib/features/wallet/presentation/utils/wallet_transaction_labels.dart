import 'package:flutter/widgets.dart';

import '../../../../core/localization/l10n_helper.dart';

/// Localized labels for wallet transaction types.
abstract final class WalletTransactionLabels {
  WalletTransactionLabels._();

  static String typeLabel(BuildContext context, String type) {
    final l10n = L10n.of(context);
    switch (type) {
      case 'BankCardTopUp':
        return l10n?.translate('walletTxBankCardTopUp') ?? 'شحن بطاقة';
      case 'BankTransferTopUp':
        return l10n?.translate('walletTxBankTransferTopUp') ?? 'تحويل بنكي';
      case 'WalletPayment':
        return l10n?.translate('walletTxWalletPayment') ?? 'دفع حجز';
      case 'WalletRefund':
        return l10n?.translate('walletTxWalletRefund') ?? 'استرداد';
      case 'ManualCredit':
        return l10n?.translate('walletTxManualCredit') ?? 'إضافة رصيد';
      // Legacy API values
      case 'TopUp':
      case 'BookingPayment':
      case 'Refund':
      case 'AdminAdjustment':
        return typeLabel(context, _legacyMap(type));
      default:
        return type;
    }
  }

  static String _legacyMap(String type) {
    switch (type) {
      case 'TopUp':
        return 'BankCardTopUp';
      case 'BookingPayment':
        return 'WalletPayment';
      case 'Refund':
        return 'WalletRefund';
      case 'AdminAdjustment':
        return 'ManualCredit';
      default:
        return type;
    }
  }

  static String directionLabel(BuildContext context, String direction) {
    final l10n = L10n.of(context);
    if (direction.toLowerCase() == 'credit') {
      return l10n?.translate('walletDirectionCredit') ?? 'إيداع';
    }
    if (direction.toLowerCase() == 'debit') {
      return l10n?.translate('walletDirectionDebit') ?? 'خصم';
    }
    return direction;
  }
}
