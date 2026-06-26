import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/bareq_nav_chevron.dart';
import '../../../wallet/domain/entities/wallet_summary.dart';
import '../../../wallet/domain/usecases/get_wallet_summary.dart';
import '../../../wallet/presentation/widgets/wallet_balance_card.dart';

/// Wallet balance summary on the profile (settings) screen.
class ProfileWalletBalanceCard extends StatefulWidget {
  const ProfileWalletBalanceCard({super.key});

  @override
  State<ProfileWalletBalanceCard> createState() =>
      _ProfileWalletBalanceCardState();
}

class _ProfileWalletBalanceCardState extends State<ProfileWalletBalanceCard> {
  WalletSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await sl<GetWalletSummaryUseCase>()();
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
        _summary = null;
      }),
      (summary) => setState(() {
        _loading = false;
        _error = null;
        _summary = summary;
      }),
    );
  }

  Future<void> _openWallet() async {
    final refresh = DateTime.now().millisecondsSinceEpoch;
    await context.push('${AppStrings.routeWallet}?refresh=$refresh');
    if (mounted) await _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _loadSummary,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: _loadSummary,
                  child: Text(l10n?.translate('retry') ?? 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openWallet,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            WalletBalanceCard(summary: summary),
            PositionedDirectional(
              top: 20,
              end: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n?.translate('wallet') ?? 'المحفظة',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 2),
                  BareqNavChevron(
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
