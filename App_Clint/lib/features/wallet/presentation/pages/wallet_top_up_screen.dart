import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../data/wallet_testing_settings.dart';
import '../../domain/usecases/start_bank_card_top_up.dart';
import '../models/wallet_top_up_status_args.dart';
import '../../domain/usecases/testing_instant_bank_card_top_up.dart';
import '../../domain/usecases/get_bank_transfer_account.dart';

/// Choose BankCard or BankTransfer — no Cash.
class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final _amountController = TextEditingController();

  late final WalletTestingSettings _testingSettings;

  bool _testingMode = false;
  bool _bankTransferAvailable = true;
  bool _checkingAccount = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _testingSettings = sl<WalletTestingSettings>();
    _testingMode = _testingSettings.enabled;
    _checkBankAccount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _checkBankAccount() async {
    final result = await sl<GetBankTransferAccountUseCase>()();
    if (!mounted) return;
    setState(() {
      _checkingAccount = false;
      _bankTransferAvailable = result.fold(
        (f) => f is! NoBankAccountConfiguredFailure,
        (_) => true,
      );
    });
  }

  Future<void> _submitBankCard() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError(
        L10n.of(context)?.translate('walletTopUpAmountInvalid') ??
            'أدخل مبلغاً أكبر من صفر.',
      );
      return;
    }

    setState(() => _submitting = true);

    final testingEnabled = _testingSettings.enabled;
    if (testingEnabled != _testingMode) {
      setState(() => _testingMode = testingEnabled);
    }

    if (testingEnabled) {
      final result = await sl<TestingInstantBankCardTopUpUseCase>()(amount);
      if (!mounted) return;
      setState(() => _submitting = false);
      result.fold(
        (failure) => _showError(failure.message),
        (_) => _finishTestingTopUpSuccess(),
      );
      return;
    }

    final result = await sl<StartBankCardTopUpUseCase>()(amount);

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (failure) => _showError(failure.message),
      (start) {
        context.pushReplacement(
          AppStrings.walletTopUpStatusRoute(start.topUpId.toString()),
          extra: WalletTopUpStatusArgs.bankCard(
            start: start,
            amount: amount,
          ),
        );
      },
    );
  }

  void _finishTestingTopUpSuccess() {
    final l10n = L10n.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.translate('walletTestingTopUpSuccess') ??
              'Testing: amount added to wallet.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(
      '${AppStrings.routeWallet}?refresh=${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('walletTopUp') ?? 'شحن المحفظة',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n?.translate('walletTestingMode') ?? 'Testing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            subtitle: Text(
              l10n?.translate('walletTestingModeHint') ??
                  'Bank card top-up credits instantly (no gateway).',
            ),
            value: _testingMode,
            onChanged: (value) async {
              setState(() => _testingMode = value);
              await _testingSettings.setEnabled(value);
            },
          ),
          if (_testingMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                l10n?.translate('walletTestingModeActive') ??
                    'Testing mode is on: بطاقة بنكية adds balance on confirm.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n?.translate('walletTopUpChooseMethod') ??
                'اختر طريقة الشحن',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.credit_card, color: AppColors.primary),
              title: Text(
                l10n?.translate('walletTopUpBankCard') ?? 'بطاقة بنكية',
              ),
              subtitle: Text(
                _testingMode
                    ? (l10n?.translate('walletTopUpBankCardTestingHint') ??
                        'شحن فوري (وضع الاختبار)')
                    : (l10n?.translate('walletTopUpBankCardHint') ??
                        'الدفع عبر بوابة الدفع الإلكترونية'),
              ),
              onTap: _submitting ? null : () => _showBankCardSheet(context),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.account_balance,
                color: _bankTransferAvailable
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              title: Text(
                l10n?.translate('walletTopUpBankTransfer') ?? 'تحويل بنكي',
              ),
              subtitle: Text(
                _checkingAccount
                    ? (l10n?.translate('loading') ?? 'Loading...')
                    : _bankTransferAvailable
                        ? (l10n?.translate('walletTopUpBankTransferHint') ??
                            'تحويل يدوي مع إيصال')
                        : (l10n?.translate('walletNoBankAccount') ??
                            'لا يوجد حساب بنكي نشط للتحويل.'),
              ),
              enabled: _bankTransferAvailable && !_checkingAccount,
              onTap: _bankTransferAvailable && !_checkingAccount
                  ? () => context.push(AppStrings.routeWalletBankTransferTopUp)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showBankCardSheet(BuildContext context) {
    final l10n = L10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n?.translate('walletTopUpBankCard') ?? 'بطاقة بنكية',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (_testingMode) ...[
                const SizedBox(height: 8),
                Text(
                  l10n?.translate('walletTestingModeActive') ??
                      'Testing: confirm adds balance immediately.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n?.translate('walletTopUpAmount') ?? 'المبلغ',
                  suffixText: l10n?.translate('lyd') ?? 'د.ل',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _submitBankCard();
                      },
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n?.translate('confirm') ?? 'تأكيد'),
              ),
            ],
          ),
        );
      },
    );
  }
}
