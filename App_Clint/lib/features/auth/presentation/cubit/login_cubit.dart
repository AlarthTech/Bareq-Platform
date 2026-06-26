import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/save_user_usecase.dart';
import 'login_state.dart';

/// Login cubit for managing login screen state
class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;
  final SaveUserUseCase saveUserUseCase;

  LoginCubit({
    required this.loginUseCase,
    required this.saveUserUseCase,
  }) : super(const LoginInitial());

  /// Login user
  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (isClosed) return;
    emit(const LoginLoading());

    final result = await loginUseCase(
      username: username,
      password: password,
    );

    result.fold(
      (failure) {
        if (isClosed) return;
        final message = _mapFailureToMessage(failure);
        if (kDebugMode) {
          debugPrint('Login failed: $message');
          if (failure is ServerFailure && failure.statusCode != null) {
            debugPrint('Login HTTP status: ${failure.statusCode}');
          }
        }
        emit(LoginError(message));
      },
      (user) async {
        // User is already saved in repository during login
        // But we can also explicitly save it here if needed
        if (isClosed) return;
        emit(LoginSuccess(user));
      },
    );
  }

  /// Map failure to user-friendly message
  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Network error. Please check your connection.';
    }
    if (failure is ServerFailure) {
      return failure.message;
    }
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is AuthFailure) {
      return failure.message;
    }
    if (failure is ForbiddenFailure) {
      return failure.message;
    }
    return failure.message;
  }
}

