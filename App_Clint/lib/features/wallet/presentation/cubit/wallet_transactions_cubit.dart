import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_wallet_transactions.dart';
import 'wallet_transactions_state.dart';

class WalletTransactionsCubit extends Cubit<WalletTransactionsState> {
  WalletTransactionsCubit(this._getTransactions)
      : super(const WalletTransactionsInitial());

  final GetWalletTransactionsUseCase _getTransactions;

  int _page = 1;
  static const _pageSize = 20;

  Future<void> loadFirstPage() async {
    _page = 1;
    emit(const WalletTransactionsLoading());
    final result = await _getTransactions(page: _page, pageSize: _pageSize);
    result.fold(
      (failure) => emit(WalletTransactionsError(failure.message)),
      (paged) => emit(
        WalletTransactionsLoaded(
          transactions: paged.items,
          hasNextPage: paged.hasNextPage,
        ),
      ),
    );
  }

  Future<void> refresh() => loadFirstPage();

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! WalletTransactionsLoaded) return;
    if (!current.hasNextPage || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    _page++;
    final result = await _getTransactions(page: _page, pageSize: _pageSize);
    result.fold(
      (failure) {
        _page--;
        emit(current.copyWith(isLoadingMore: false));
      },
      (paged) => emit(
        WalletTransactionsLoaded(
          transactions: [...current.transactions, ...paged.items],
          hasNextPage: paged.hasNextPage,
        ),
      ),
    );
  }
}
