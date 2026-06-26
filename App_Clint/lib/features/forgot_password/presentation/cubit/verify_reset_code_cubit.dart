import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/constants/forgot_password_constants.dart';
import '../../domain/usecases/request_reset_otp_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import 'forgot_password_flow_cubit.dart';
import 'verify_reset_code_state.dart';

class VerifyResetCodeCubit extends Cubit<VerifyResetCodeState> {
  VerifyResetCodeCubit({
    required ForgotPasswordFlowCubit flowCubit,
    required RequestResetOtpUseCase requestResetOtpUseCase,
    required VerifyResetCodeUseCase verifyResetCodeUseCase,
  })  : _flowCubit = flowCubit,
        _requestResetOtpUseCase = requestResetOtpUseCase,
        _verifyResetCodeUseCase = verifyResetCodeUseCase,
        super(const VerifyResetCodeInitial()) {
    _startResendCountdown();
  }

  final ForgotPasswordFlowCubit _flowCubit;
  final RequestResetOtpUseCase _requestResetOtpUseCase;
  final VerifyResetCodeUseCase _verifyResetCodeUseCase;

  Timer? _timer;
  static const int _resendCooldownSeconds = 60;

  String? get identifier => _flowCubit.state.identifier;

  void _startResendCountdown() {
    _timer?.cancel();
    emit(const VerifyResetCodeInitial(resendSeconds: _resendCooldownSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      final current = state;
      if (current is! VerifyResetCodeInitial &&
          current is! VerifyResetCodeResent &&
          current is! VerifyResetCodeError) {
        return;
      }
      final seconds = switch (current) {
        VerifyResetCodeInitial(:final resendSeconds) => resendSeconds,
        VerifyResetCodeResent(:final resendSeconds) => resendSeconds,
        VerifyResetCodeError(:final resendSeconds) => resendSeconds,
        _ => 0,
      };
      if (seconds <= 0) return;
      final next = seconds - 1;
      if (current is VerifyResetCodeInitial) {
        emit(VerifyResetCodeInitial(resendSeconds: next));
      } else if (current is VerifyResetCodeResent) {
        emit(VerifyResetCodeResent(resendSeconds: next));
      } else if (current is VerifyResetCodeError) {
        emit(VerifyResetCodeError(current.message, resendSeconds: next));
      }
    });
  }

  int get resendSeconds {
    final s = state;
    return switch (s) {
      VerifyResetCodeInitial(:final resendSeconds) => resendSeconds,
      VerifyResetCodeResent(:final resendSeconds) => resendSeconds,
      VerifyResetCodeError(:final resendSeconds) => resendSeconds,
      _ => 0,
    };
  }

  bool get canResend => resendSeconds <= 0;

  Future<void> verifyCode(String code) async {
    if (isClosed || state is VerifyResetCodeLoading) return;
    final id = identifier;
    if (id == null || id.isEmpty) return;

    emit(const VerifyResetCodeLoading());

    final result = await _verifyResetCodeUseCase(
      identifier: id,
      code: code,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        VerifyResetCodeError(
          _mapFailure(failure, otp: true),
          resendSeconds: resendSeconds,
        ),
      ),
      (resetToken) {
        _flowCubit.setResetToken(resetToken);
        emit(const VerifyResetCodeVerified());
      },
    );
  }

  Future<void> resendCode() async {
    if (isClosed || !canResend || state is VerifyResetCodeLoading) return;
    final id = identifier;
    if (id == null || id.isEmpty) return;

    emit(const VerifyResetCodeLoading());

    final result = await _requestResetOtpUseCase(id);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        VerifyResetCodeError(
          _mapFailure(failure),
          resendSeconds: resendSeconds,
        ),
      ),
      (_) {
        emit(const VerifyResetCodeResent(
          resendSeconds: _resendCooldownSeconds,
        ));
        _startResendCountdown();
      },
    );
  }

  String _mapFailure(Failure failure, {bool otp = false}) {
    if (failure is ValidationFailure) {
      if (otp) {
        return failure.message.isNotEmpty
            ? failure.message
            : ForgotPasswordConstants.invalidOtpMessageAr;
      }
      return failure.message;
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

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
