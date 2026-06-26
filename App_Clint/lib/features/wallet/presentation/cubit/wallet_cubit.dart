import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_wallet_summary.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._getWalletSummary) : super(const WalletInitial());

  final GetWalletSummaryUseCase _getWalletSummary;

  Future<void> load() async {
    emit(const WalletLoading());
    final result = await _getWalletSummary();
    result.fold(
      (failure) => emit(WalletError(_message(failure))),
      (summary) => emit(WalletLoaded(summary)),
    );
  }

  String _message(Failure failure) => failure.message;
}
