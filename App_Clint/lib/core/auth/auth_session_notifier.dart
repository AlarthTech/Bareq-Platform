import 'package:flutter/foundation.dart';

import '../constants/app_strings.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/usecases/check_authentication_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/entities/app_user_role.dart';

/// Drives GoRouter refresh and post-login / post-restore home routing.
class AuthSessionNotifier extends ChangeNotifier {
  bool _loggedIn = false;
  AppUserRole? _role;
  bool _requiresProfileCompletion = false;

  bool get isLoggedIn => _loggedIn;

  AppUserRole? get role => _role;

  bool get requiresProfileCompletion => _requiresProfileCompletion;

  String get postAuthHomeRoute => _routeForRole(_role);

  static String _routeForRole(AppUserRole? r) {
    switch (r) {
      case AppUserRole.admin:
        return AppStrings.routeAdminHome;
      case AppUserRole.company:
        return AppStrings.routeCompanyHome;
      case AppUserRole.customer:
      case null:
        return AppStrings.routeHome;
    }
  }

  /// Call after DI is ready (injection passes use cases to avoid circular imports).
  Future<void> restore({
    required CheckAuthenticationUseCase checkAuth,
    required GetCurrentUserUseCase getCurrentUser,
    required Future<bool> Function() getRequiresProfileCompletion,
  }) async {
    final authOk = await checkAuth();
    await authOk.fold(
      (_) async {
        _loggedIn = false;
        _role = null;
        _requiresProfileCompletion = false;
      },
      (ok) async {
        if (!ok) {
          _loggedIn = false;
          _role = null;
          _requiresProfileCompletion = false;
          return;
        }
        final userRes = await getCurrentUser();
        userRes.fold(
          (_) {
            _loggedIn = false;
            _role = null;
            _requiresProfileCompletion = false;
          },
          (user) {
            _applyUser(user);
          },
        );
        if (_loggedIn) {
          _requiresProfileCompletion = await getRequiresProfileCompletion();
        }
      },
    );
    notifyListeners();
  }

  void setLoggedIn(
    User user, {
    bool requiresProfileCompletion = false,
  }) {
    _applyUser(user);
    _requiresProfileCompletion = requiresProfileCompletion;
    notifyListeners();
  }

  void clearProfileCompletionFlag() {
    _requiresProfileCompletion = false;
    notifyListeners();
  }

  void clear() {
    _loggedIn = false;
    _role = null;
    _requiresProfileCompletion = false;
    notifyListeners();
  }

  void _applyUser(User? user) {
    if (user == null ||
        user.token == null ||
        user.token!.isEmpty) {
      _loggedIn = false;
      _role = null;
      return;
    }
    _loggedIn = true;
    _role = user.role;
  }
}
