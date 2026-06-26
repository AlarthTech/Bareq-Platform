import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../domain/entities/bank_transfer_account.dart';
import '../../domain/entities/wallet_top_up_request.dart';
import '../../domain/usecases/create_wallet_top_up.dart';
import '../../domain/usecases/get_bank_transfer_account.dart';
import '../../domain/usecases/upload_receipt_image.dart';
import '../models/wallet_top_up_status_args.dart';
import '../widgets/bank_account_details_card.dart';

class WalletBankTransferTopUpScreen extends StatefulWidget {
  const WalletBankTransferTopUpScreen({super.key});

  @override
  State<WalletBankTransferTopUpScreen> createState() =>
      _WalletBankTransferTopUpScreenState();
}

class _WalletBankTransferTopUpScreenState
    extends State<WalletBankTransferTopUpScreen> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  BankTransferAccount? _account;
  File? _receiptFile;
  bool _loadingAccount = true;
  bool _uploading = false;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    setState(() {
      _loadingAccount = true;
      _loadError = null;
    });
    final result = await sl<GetBankTransferAccountUseCase>()();
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _loadingAccount = false;
          _loadError = failure.message;
          _account = null;
        });
      },
      (account) {
        setState(() {
          _loadingAccount = false;
          _account = account;
        });
      },
    );
  }

  Future<void> _pickReceipt() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _receiptFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final l10n = L10n.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError(
        l10n?.translate('walletTopUpAmountInvalid') ??
            'أدخل مبلغاً أكبر من صفر.',
      );
      return;
    }
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      _showError(
        l10n?.translate('walletTransferReferenceRequired') ??
            'أدخل رقم المرجع للتحويل.',
      );
      return;
    }
    if (_receiptFile == null) {
      _showError(
        l10n?.translate('walletReceiptRequired') ??
            'يرجى رفع صورة الإيصال.',
      );
      return;
    }

    setState(() => _uploading = true);
    final uploadResult = await sl<UploadReceiptImageUseCase>()(_receiptFile!);
    if (!mounted) return;

    String? receiptUrl;
    uploadResult.fold(
      (f) => _showError(f.message),
      (url) => receiptUrl = url,
    );
    if (receiptUrl == null) {
      setState(() => _uploading = false);
      return;
    }

    setState(() {
      _uploading = false;
      _submitting = true;
    });

    final result = await sl<CreateWalletTopUpUseCase>()(
      WalletTopUpRequest.bankTransfer(
        requestedAmount: amount,
        transferReferenceNumber: reference,
        transferReceiptImageUrl: receiptUrl!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (failure) => _showError(failure.message),
      (topUp) {
        context.pushReplacement(
          AppStrings.walletTopUpStatusRoute(topUp.id.toString()),
          extra: WalletTopUpStatusArgs.transfer(topUp: topUp),
        );
      },
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
    final busy = _uploading || _submitting;

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('walletTopUpBankTransfer') ?? 'تحويل بنكي',
        showBackButton: true,
      ),
      body: _loadingAccount
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadAccount,
                          child: Text(l10n?.translate('retry') ?? 'Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_account != null)
                      BankAccountDetailsCard(account: _account!),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _amountController,
                      enabled: !busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            l10n?.translate('walletTopUpAmount') ?? 'المبلغ',
                        suffixText: l10n?.translate('lyd') ?? 'د.ل',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _referenceController,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: l10n?.translate('walletTransferReference') ??
                            'رقم مرجع التحويل',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _pickReceipt,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _receiptFile == null
                            ? (l10n?.translate('walletUploadReceipt') ??
                                'رفع إيصال التحويل')
                            : (l10n?.translate('walletReceiptSelected') ??
                                'تم اختيار الإيصال'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      enabled: !busy,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n?.translate('walletTopUpNotes') ??
                            'ملاحظات (اختياري)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: busy
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
  }
}
