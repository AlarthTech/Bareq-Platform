import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/constants/forgot_password_constants.dart';
import '../../domain/usecases/request_reset_otp_usecase.dart';
import 'forgot_password_flow_cubit.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(
    this._requestResetOtpUseCase,
    this._flowCubit,
  ) : super(const ForgotPasswordInitial());

  final RequestResetOtpUseCase _requestResetOtpUseCase;
  final ForgotPasswordFlowCubit _flowCubit;

  Future<void> requestOtp(String identifier) async {
    if (isClosed || state is ForgotPasswordLoading) return;
    emit(const ForgotPasswordLoading());

    final trimmed = identifier.trim();
    final result = await _requestResetOtpUseCase(trimmed);
    if (isClosed) return;

    result.fold(
      (failure) => emit(ForgotPasswordError(_mapFailure(failure))),
      (_) {
        _flowCubit.setIdentifier(trimmed);
        emit(ForgotPasswordOtpSent(identifier: trimmed));
      },
    );
  }

  String get genericSuccessMessage =>
      ForgotPasswordConstants.genericOtpSentMessageAr;

  String _mapFailure(Failure failure) {
    if (failure is RateLimitFailure) return failure.message;
    if (failure is ValidationFailure) return failure.message;
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
