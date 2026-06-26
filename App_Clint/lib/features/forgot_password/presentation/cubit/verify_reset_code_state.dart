import 'package:equatable/equatable.dart';

abstract class VerifyResetCodeState extends Equatable {
  const VerifyResetCodeState();

  @override
  List<Object?> get props => [];
}

class VerifyResetCodeInitial extends VerifyResetCodeState {
  const VerifyResetCodeInitial({this.resendSeconds = 60});

  final int resendSeconds;

  @override
  List<Object?> get props => [resendSeconds];
}

class VerifyResetCodeLoading extends VerifyResetCodeState {
  const VerifyResetCodeLoading();
}

class VerifyResetCodeVerified extends VerifyResetCodeState {
  const VerifyResetCodeVerified();
}

class VerifyResetCodeResent extends VerifyResetCodeState {
  const VerifyResetCodeResent({
    required this.resendSeconds,
  });

  final int resendSeconds;

  @override
  List<Object?> get props => [resendSeconds];
}

class VerifyResetCodeError extends VerifyResetCodeState {
  const VerifyResetCodeError(this.message, {this.resendSeconds = 60});

  final String message;
  final int resendSeconds;

  @override
  List<Object?> get props => [message, resendSeconds];
}
