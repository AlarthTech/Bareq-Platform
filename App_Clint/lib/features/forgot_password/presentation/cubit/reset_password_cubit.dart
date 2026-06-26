import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/constants/forgot_password_constants.dart';
import '../../domain/usecases/reset_password_with_token_usecase.dart';
import 'forgot_password_flow_cubit.dart';
import 'reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit({
    required ForgotPasswordFlowCubit flowCubit,
    required ResetPasswordWithTokenUseCase resetPasswordWithTokenUseCase,
  })  : _flowCubit = flowCubit,
        _resetPasswordWithTokenUseCase = resetPasswordWithTokenUseCase,
        super(const ResetPasswordInitial());

  final ForgotPasswordFlowCubit _flowCubit;
  final ResetPasswordWithTokenUseCase _resetPasswordWithTokenUseCase;

  Future<void> submit(String newPassword) async {
    if (isClosed || state is ResetPasswordLoading) return;

    final identifier = _flowCubit.state.identifier;
    final resetToken = _flowCubit.state.resetToken;
    if (identifier == null ||
        identifier.isEmpty ||
        resetToken == null ||
        resetToken.isEmpty) {
      emit(
        const ResetPasswordError(
          'رمز إعادة التعيين غير صالح أو منتهي الصلاحية.',
        ),
      );
      return;
    }

    emit(const ResetPasswordLoading());

    final result = await _resetPasswordWithTokenUseCase(
      identifier: identifier,
      resetToken: resetToken,
      newPassword: newPassword,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(ResetPasswordError(_mapFailure(failure))),
      (_) {
        _flowCubit.clear();
        emit(const ResetPasswordSuccess());
      },
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : ForgotPasswordConstants.invalidResetTokenMessageAr;
    }
    if (failure is RateLimitFailure) return failure.message;
    if (failure is ServerFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
    }
    if (failure is NetworkFailure) {
      return 'خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }
    if (failure is AuthFailure) return failure.message;
    return failure.message;
  }
}
