import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// In-memory holder for identifier + resetToken across the 3-step flow.
/// Never persisted to SharedPreferences or secure storage.
class ForgotPasswordFlowCubit extends Cubit<ForgotPasswordFlowState> {
  ForgotPasswordFlowCubit() : super(const ForgotPasswordFlowState());

  void setIdentifier(String identifier) {
    emit(
      ForgotPasswordFlowState(
        identifier: identifier.trim(),
        resetToken: state.resetToken,
      ),
    );
  }

  void setResetToken(String resetToken) {
    emit(
      ForgotPasswordFlowState(
        identifier: state.identifier,
        resetToken: resetToken,
      ),
    );
  }

  void clear() {
    emit(const ForgotPasswordFlowState());
  }
}

class ForgotPasswordFlowState extends Equatable {
  const ForgotPasswordFlowState({this.identifier, this.resetToken});

  final String? identifier;
  final String? resetToken;

  bool get hasIdentifier =>
      identifier != null && identifier!.trim().isNotEmpty;

  bool get hasResetToken =>
      resetToken != null && resetToken!.trim().isNotEmpty;

  @override
  List<Object?> get props => [identifier, resetToken];
}
