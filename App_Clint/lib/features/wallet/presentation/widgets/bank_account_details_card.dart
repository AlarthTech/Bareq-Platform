import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/entities/bank_transfer_account.dart';

class BankAccountDetailsCard extends StatelessWidget {
  const BankAccountDetailsCard({super.key, required this.account});

  final BankTransferAccount account;

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${L10n.of(context)?.translate('copied') ?? 'Copied'}: $label',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.translate('walletTransferToAccount') ?? 'Transfer to this account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _CopyRow(
            label: l10n?.translate('bankName') ?? 'Bank',
            value: account.bankName,
            onCopy: () => _copy(context, 'Bank', account.bankName),
          ),
          _CopyRow(
            label: l10n?.translate('accountHolder') ?? 'Account holder',
            value: account.accountHolderName,
            onCopy: () =>
                _copy(context, 'Holder', account.accountHolderName),
          ),
          _CopyRow(
            label: l10n?.translate('accountNumber') ?? 'Account number',
            value: account.accountNumber,
            onCopy: () => _copy(context, 'Account', account.accountNumber),
          ),
          if (account.iban != null && account.iban!.isNotEmpty)
            _CopyRow(
              label: 'IBAN',
              value: account.iban!,
              onCopy: () => _copy(context, 'IBAN', account.iban!),
            ),
          if (account.branchName != null && account.branchName!.isNotEmpty)
            _CopyRow(
              label: l10n?.translate('branchName') ?? 'Branch',
              value: account.branchName!,
              onCopy: () => _copy(context, 'Branch', account.branchName!),
            ),
          if (account.instructions != null &&
              account.instructions!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              account.instructions!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}
