import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/booking_price_formatter.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../cubit/wallet_transactions_cubit.dart';
import '../cubit/wallet_transactions_state.dart';
import '../utils/wallet_transaction_labels.dart';

class WalletTransactionsScreen extends StatelessWidget {
  const WalletTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletTransactionsCubit>()..loadFirstPage(),
      child: const _WalletTransactionsBody(),
    );
  }
}

class _WalletTransactionsBody extends StatefulWidget {
  const _WalletTransactionsBody();

  @override
  State<_WalletTransactionsBody> createState() => _WalletTransactionsBodyState();
}

class _WalletTransactionsBodyState extends State<_WalletTransactionsBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<WalletTransactionsCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('walletTransactions') ?? 'سجل المعاملات',
        showBackButton: true,
      ),
      body: BlocBuilder<WalletTransactionsCubit, WalletTransactionsState>(
        builder: (context, state) {
          if (state is WalletTransactionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WalletTransactionsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<WalletTransactionsCubit>().loadFirstPage(),
                      child: Text(l10n?.translate('retry') ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is WalletTransactionsLoaded) {
            if (state.transactions.isEmpty) {
              return Center(
                child: Text(
                  l10n?.translate('walletNoTransactions') ??
                      'لا توجد معاملات بعد.',
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<WalletTransactionsCubit>().refresh(),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.transactions.length +
                    (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index >= state.transactions.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _TransactionTile(tx: state.transactions[index]);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final locale = l10n?.locale ?? const Locale('en');
    final dateText = WesternNumerals.normalize(
      DateFormat.yMMMd(locale.toString()).add_jm().format(tx.createdAt),
    );
    final sign = tx.isCredit ? '+' : '−';
    final amountColor = tx.isCredit ? AppColors.success : AppColors.error;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: tx.bookingId != null
            ? () => context.push(
                  AppStrings.bookingDetailsRoute(tx.bookingId.toString()),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WalletTransactionLabels.typeLabel(context, tx.type),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      WalletTransactionLabels.directionLabel(
                        context,
                        tx.direction,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${BookingPriceFormatter.formatAmount(context, tx.amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(status: tx.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color color = AppColors.textSecondary;
    if (lower == 'completed') color = AppColors.success;
    if (lower == 'pending') color = AppColors.accent;
    if (lower == 'rejected') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
