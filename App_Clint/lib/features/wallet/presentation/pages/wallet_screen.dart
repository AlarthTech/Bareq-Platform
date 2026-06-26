import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/wallet_balance_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, this.refreshToken});

  /// Changes when returning from testing top-up to force balance reload.
  final String? refreshToken;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(refreshToken ?? 'wallet'),
      create: (_) => sl<WalletCubit>()..load(),
      child: const _WalletScreenBody(),
    );
  }
}

class _WalletScreenBody extends StatelessWidget {
  const _WalletScreenBody();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('wallet') ?? 'المحفظة',
        showBackButton: true,
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WalletError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.read<WalletCubit>().load(),
                      child: Text(l10n?.translate('retry') ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is WalletLoaded) {
            final summary = state.summary;
            return RefreshIndicator(
              onRefresh: () => context.read<WalletCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  WalletBalanceCard(summary: summary),
                  if (!summary.isWalletPaymentEnabled) ...[
                    const SizedBox(height: 16),
                    _InfoBanner(
                      message: l10n?.translate('walletPaymentDisabledBanner') ??
                          'الدفع بالمحفظة غير متاح حالياً.',
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(AppStrings.routeWalletTopUp),
                    icon: const Icon(Icons.add_card),
                    label: Text(
                      l10n?.translate('walletTopUp') ?? 'شحن المحفظة',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(AppStrings.routeWalletTransactions),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(
                      l10n?.translate('walletTransactions') ??
                          'سجل المعاملات',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
