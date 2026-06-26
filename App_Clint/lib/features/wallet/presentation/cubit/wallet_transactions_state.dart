import 'package:equatable/equatable.dart';

import '../../domain/entities/wallet_transaction.dart';

sealed class WalletTransactionsState extends Equatable {
  const WalletTransactionsState();

  @override
  List<Object?> get props => [];
}

class WalletTransactionsInitial extends WalletTransactionsState {
  const WalletTransactionsInitial();
}

class WalletTransactionsLoading extends WalletTransactionsState {
  const WalletTransactionsLoading();
}

class WalletTransactionsLoaded extends WalletTransactionsState {
  const WalletTransactionsLoaded({
    required this.transactions,
    required this.hasNextPage,
    this.isLoadingMore = false,
  });

  final List<WalletTransaction> transactions;
  final bool hasNextPage;
  final bool isLoadingMore;

  WalletTransactionsLoaded copyWith({
    List<WalletTransaction>? transactions,
    bool? hasNextPage,
    bool? isLoadingMore,
  }) {
    return WalletTransactionsLoaded(
      transactions: transactions ?? this.transactions,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [transactions, hasNextPage, isLoadingMore];
}

class WalletTransactionsError extends WalletTransactionsState {
  const WalletTransactionsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
