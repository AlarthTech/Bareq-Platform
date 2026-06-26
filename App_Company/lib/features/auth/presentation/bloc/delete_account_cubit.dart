import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/delete_my_company_account_usecase.dart';

sealed class DeleteAccountState extends Equatable {
  const DeleteAccountState();

  @override
  List<Object?> get props => [];
}

class DeleteAccountIdle extends DeleteAccountState {
  const DeleteAccountIdle();
}

class DeleteAccountLoading extends DeleteAccountState {
  const DeleteAccountLoading();
}

class DeleteAccountPasswordError extends DeleteAccountState {
  const DeleteAccountPasswordError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DeleteAccountActiveBookings extends DeleteAccountState {
  const DeleteAccountActiveBookings(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DeleteAccountUnauthorized extends DeleteAccountState {
  const DeleteAccountUnauthorized(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DeleteAccountRateLimited extends DeleteAccountState {
  const DeleteAccountRateLimited(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DeleteAccountFailure extends DeleteAccountState {
  const DeleteAccountFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DeleteAccountSuccess extends DeleteAccountState {
  const DeleteAccountSuccess();
}

class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit({
    required DeleteMyCompanyAccountUseCase deleteMyCompanyAccountUseCase,
  })  : _deleteMyCompanyAccountUseCase = deleteMyCompanyAccountUseCase,
        super(const DeleteAccountIdle());

  final DeleteMyCompanyAccountUseCase _deleteMyCompanyAccountUseCase;

  Future<void> deleteAccount(String password) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      emit(const DeleteAccountPasswordError('كلمة المرور مطلوبة.'));
      return;
    }

    emit(const DeleteAccountLoading());
    final result = await _deleteMyCompanyAccountUseCase(trimmed);
    result.fold(
      (failure) {
        switch (failure) {
          case ValidationFailure():
            emit(DeleteAccountPasswordError(failure.message));
          case ActiveBookingsFailure():
            emit(DeleteAccountActiveBookings(failure.message));
          case UnauthorizedFailure():
            emit(DeleteAccountUnauthorized(failure.message));
          case RateLimitFailure():
            emit(DeleteAccountRateLimited(failure.message));
          default:
            emit(DeleteAccountFailure(failure.message));
        }
      },
      (_) => emit(const DeleteAccountSuccess()),
    );
  }

  void resetStatus() => emit(const DeleteAccountIdle());
}
