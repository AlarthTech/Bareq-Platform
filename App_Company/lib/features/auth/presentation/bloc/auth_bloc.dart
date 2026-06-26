import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_session.dart';
import '../../data/models/user_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/company_session_storage.dart';
import '../../../../core/storage/secure_token_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:convert';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final ApiClient apiClient;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.apiClient,
  }) : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<UserProfileUpdatedEvent>(_onUserProfileUpdated);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await loginUseCase(
      LoginParams(
        username: event.username,
        password: event.password,
      ),
    );

    if (emit.isDone) return;

    await result.fold<Future<void>>(
      (failure) async {
        if (emit.isDone) return;
        emit(AuthError(failure.message));
      },
      (session) async {
        await _saveSession(session);
        if (emit.isDone) return;
        emit(AuthAuthenticated(session.user));
      },
    );
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await registerUseCase(
      RegisterParams(
        fullName: event.fullName,
        phone: event.phone,
        email: event.email,
        password: event.password,
        cityId: event.cityId,
      ),
    );

    if (emit.isDone) return;

    await result.fold<Future<void>>(
      (failure) async {
        if (emit.isDone) return;
        emit(AuthError(failure.message));
      },
      (user) async {
        final loginUsername = event.email.trim().isNotEmpty
            ? event.email.trim()
            : event.phone.trim();
        final loginResult = await loginUseCase(
          LoginParams(username: loginUsername, password: event.password),
        );
        if (emit.isDone) return;

        await loginResult.fold<Future<void>>(
          (failure) async {
            if (emit.isDone) return;
            emit(
              AuthError(
                'تم إنشاء الحساب لكن فشل تسجيل الدخول التلقائي. '
                'يرجى تسجيل الدخول يدوياً.',
              ),
            );
          },
          (session) async {
            await _saveSession(session);
            apiClient.setAuthToken(session.token);
            if (emit.isDone) return;
            emit(AuthAuthenticated(session.user));
          },
        );
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    apiClient.clearAuthToken();
    await CompanySessionStorage.clear();
    await _clearUser();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onUserProfileUpdated(
    UserProfileUpdatedEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _saveUser(event.user);
    if (emit.isDone) return;
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    final token = await SecureTokenStorage.readToken();

    if (userJson != null && token != null && token.isNotEmpty) {
      try {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap).toEntity();
        apiClient.setAuthToken(token);
        emit(AuthAuthenticated(user));
      } catch (e) {
        await _clearUser();
        apiClient.clearAuthToken();
        emit(const AuthUnauthenticated());
      }
    } else {
      if (userJson != null) {
        await _clearUser();
      }
      apiClient.clearAuthToken();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    await _saveUser(session.user);
    await SecureTokenStorage.saveToken(session.token);
  }

  Future<void> _saveUser(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final userModel = UserModel(
      id: user.id,
      fullName: user.fullName,
      phone: user.phone,
      email: user.email,
      userTypeId: user.userTypeId,
      userTypeName: user.userTypeName,
      createdAt: user.createdAt,
    );
    await prefs.setString(AppConstants.userKey, json.encode(userModel.toJson()));
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
    await SecureTokenStorage.clearToken();
  }
}
