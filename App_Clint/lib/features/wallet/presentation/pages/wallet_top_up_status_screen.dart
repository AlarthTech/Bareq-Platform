import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/booking_price_formatter.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../data/wallet_top_up_url_cache.dart';
import '../../data/utils/wallet_payment_url.dart';
import '../../domain/entities/bank_card_top_up_start.dart';
import '../../domain/entities/wallet_top_up.dart';
import '../../domain/usecases/get_top_up_status.dart';
import '../../domain/usecases/get_wallet_summary.dart';

class WalletTopUpStatusScreen extends StatefulWidget {
  const WalletTopUpStatusScreen({
    super.key,
    required this.topUpId,
    this.initialStart,
    this.initialAmount,
    this.initialTopUp,
  });

  final String topUpId;
  final BankCardTopUpStart? initialStart;
  final double? initialAmount;
  final WalletTopUp? initialTopUp;

  @override
  State<WalletTopUpStatusScreen> createState() => _WalletTopUpStatusScreenState();
}

class _WalletTopUpStatusScreenState extends State<WalletTopUpStatusScreen> {
  WalletTopUp? _topUp;
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;
  WebViewController? _webController;
  bool _showGateway = false;
  String? _cachedPaymentUrl;

  int? get _topUpIdInt => int.tryParse(widget.topUpId);

  String? get _resolvedPaymentUrl {
    if (isWalletPaymentWebUrl(widget.initialStart?.paymentUrl)) {
      return widget.initialStart!.paymentUrl;
    }
    final fromTopUp = _topUp?.gatewayUrl;
    if (isWalletPaymentWebUrl(fromTopUp)) return fromTopUp;
    if (isWalletPaymentWebUrl(_cachedPaymentUrl)) return _cachedPaymentUrl;
    final fromInitial = widget.initialTopUp?.gatewayUrl;
    if (isWalletPaymentWebUrl(fromInitial)) return fromInitial;
    return null;
  }

  bool get _isPendingBankCard {
    if (_topUp != null) {
      return _topUp!.isBankCard && _topUp!.isPending;
    }
    return widget.initialStart != null;
  }

  bool get _hasGatewayReferenceOnly {
    final ref = _topUp?.gatewayPaymentReference?.trim();
    return _isPendingBankCard &&
        _resolvedPaymentUrl == null &&
        ref != null &&
        ref.isNotEmpty;
  }

  double? get _displayAmount =>
      _topUp?.requestedAmount ?? widget.initialAmount;

  @override
  void initState() {
    super.initState();
    _topUp = widget.initialTopUp;
    _primePaymentUrlFromStart();
    _loadCachedPaymentUrl();
    _maybeInitGateway();
    _loadStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (_topUp?.isTerminal == true) return;
      _loadStatus(silent: true);
    });
  }

  void _primePaymentUrlFromStart() {
    final start = widget.initialStart;
    if (start == null || !isWalletPaymentWebUrl(start.paymentUrl)) return;
    _cachedPaymentUrl = start.paymentUrl;
    sl<WalletTopUpUrlCache>().save(start.topUpId, start.paymentUrl);
  }

  void _loadCachedPaymentUrl() {
    final id = _topUpIdInt;
    if (id == null) return;
    _cachedPaymentUrl ??= sl<WalletTopUpUrlCache>().read(id);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus({bool silent = false}) async {
    final id = _topUpIdInt;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid top-up id';
      });
      return;
    }

    if (!silent) setState(() => _loading = true);
    final result = await sl<GetTopUpStatusUseCase>()(id);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (topUp) async {
        final wasTerminal = _topUp?.isTerminal == true;
        setState(() {
          _loading = false;
          _error = null;
          _topUp = topUp;
        });
        _maybeInitGateway();
        if (topUp.isTerminal && !wasTerminal) {
          await sl<GetWalletSummaryUseCase>()();
          if (topUp.isCompleted) {
            await sl<WalletTopUpUrlCache>().remove(id);
            if (mounted) setState(() => _showGateway = false);
          }
        }
      },
    );
  }

  void _maybeInitGateway() {
    final url = _resolvedPaymentUrl;
    if (!_isPendingBankCard || url == null || url.isEmpty) return;
    if (_webController != null) return;

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    setState(() => _showGateway = true);
  }

  Future<void> _openGatewayExternally() async {
    final url = _resolvedPaymentUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.of(context)?.translate('walletTopUpOpenGatewayFailed') ??
                'Could not open payment page.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final topUp = _topUp;
    final paymentUrl = _resolvedPaymentUrl;
    final amount = _displayAmount;

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('walletTopUpStatus') ?? 'حالة الشحن',
        showBackButton: true,
      ),
      body: _loading && topUp == null && amount == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      if (amount != null) ...[
                        Text(
                          BookingPriceFormatter.formatAmount(context, amount),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (topUp != null) ...[
                        if (topUp.approvedAmount != null) ...[
                          Text(
                            '${l10n?.translate('walletApprovedAmount') ?? 'المبلغ المعتمد'}: ${BookingPriceFormatter.formatAmount(context, topUp.approvedAmount!)}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _StatusBanner(topUp: topUp),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage(context, topUp),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ] else if (_isPendingBankCard) ...[
                        _StatusBanner(
                          topUp: WalletTopUp(
                            id: _topUpIdInt ?? 0,
                            customerId: 0,
                            requestedAmount: amount ?? 0,
                            paymentMethod: 'BankCard',
                            status: 'Pending',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.translate('walletTopUpCardPending') ??
                              'أكمل الدفع في بوابة الدفع.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                      if (_hasGatewayReferenceOnly) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            l10n?.translate('walletTopUpPendingNoPaymentUrl') ??
                                'Payment is still pending. Complete payment in the gateway, or enable Testing mode for instant top-up.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                      if (_isPendingBankCard && paymentUrl != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _openGatewayExternally,
                          icon: const Icon(Icons.open_in_new),
                          label: Text(
                            l10n?.translate('walletTopUpOpenGateway') ??
                                'Open payment gateway',
                          ),
                        ),
                      ],
                      if (_showGateway &&
                          _webController != null &&
                          _isPendingBankCard &&
                          paymentUrl != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 320,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: WebViewWidget(controller: _webController!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () => context.go(AppStrings.routeWallet),
                      child: Text(
                        l10n?.translate('backToWallet') ?? 'العودة للمحفظة',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _statusMessage(BuildContext context, WalletTopUp topUp) {
    final l10n = L10n.of(context);
    if (topUp.isBankCard) {
      if (topUp.isCompleted) {
        return l10n?.translate('walletTopUpCardCompleted') ??
            'تم شحن المحفظة بنجاح.';
      }
      if (topUp.isFailed) {
        return l10n?.translate('walletTopUpCardFailed') ??
            'فشل الدفع بالبطاقة.';
      }
      return l10n?.translate('walletTopUpCardPending') ??
          'أكمل الدفع في بوابة الدفع.';
    }
    if (topUp.isApproved) {
      return l10n?.translate('walletTopUpTransferApproved') ??
          'تمت الموافقة على التحويل وإضافة الرصيد.';
    }
    if (topUp.isRejected) {
      return l10n?.translate('walletTopUpTransferRejected') ??
          'تم رفض طلب التحويل.';
    }
    return l10n?.translate('walletTopUpTransferPending') ??
        'في انتظار موافقة الإدارة';
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.topUp});

  final WalletTopUp topUp;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.accent;
    IconData icon = Icons.hourglass_top;

    if (topUp.isCompleted || topUp.isApproved) {
      color = AppColors.success;
      icon = Icons.check_circle_outline;
    } else if (topUp.isRejected || topUp.isFailed) {
      color = AppColors.error;
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              topUp.status,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
