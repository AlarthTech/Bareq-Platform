import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/request_password_reset_otp.dart';
import '../../domain/usecases/verify_password_reset_code.dart';
import '../../domain/usecases/reset_password.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class ForgotPasswordOtpSent extends ForgotPasswordState {
  const ForgotPasswordOtpSent(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordCodeVerified extends ForgotPasswordState {
  const ForgotPasswordCodeVerified(this.resetToken);

  final String resetToken;

  @override
  List<Object?> get props => [resetToken];
}

class ForgotPasswordResetSuccess extends ForgotPasswordState {
  const ForgotPasswordResetSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordError extends ForgotPasswordState {
  const ForgotPasswordError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({
    required RequestPasswordResetOtpUseCase requestOtpUseCase,
    required VerifyPasswordResetCodeUseCase verifyCodeUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _requestOtpUseCase = requestOtpUseCase,
        _verifyCodeUseCase = verifyCodeUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        super(const ForgotPasswordInitial());

  final RequestPasswordResetOtpUseCase _requestOtpUseCase;
  final VerifyPasswordResetCodeUseCase _verifyCodeUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  Future<void> requestOtp(String email) async {
    emit(const ForgotPasswordLoading());
    final result = await _requestOtpUseCase(email);
    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (message) => emit(ForgotPasswordOtpSent(message)),
    );
  }

  Future<void> verifyCode({
    required String email,
    required String code,
  }) async {
    emit(const ForgotPasswordLoading());
    final result = await _verifyCodeUseCase(email: email, code: code);
    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (resetToken) => emit(ForgotPasswordCodeVerified(resetToken)),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    emit(const ForgotPasswordLoading());
    final result = await _resetPasswordUseCase(
      email: email,
      resetToken: resetToken,
      newPassword: newPassword,
    );
    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (message) => emit(ForgotPasswordResetSuccess(message)),
    );
  }

  void resetToInitial() => emit(const ForgotPasswordInitial());
}
