import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/company/presentation/cubit/company_guard_cubit.dart';
import '../../features/notifications/presentation/state/notifications_cubit.dart';

/// Notifies [GoRouter] when auth or company-guard state changes.
class AppRouterRefreshNotifier extends ChangeNotifier {
  AppRouterRefreshNotifier({
    required AuthBloc authBloc,
    required CompanyGuardCubit companyGuardCubit,
    required NotificationsCubit notificationsCubit,
  })  : _authBloc = authBloc,
        _companyGuardCubit = companyGuardCubit,
        _notificationsCubit = notificationsCubit {
    _authSub = _authBloc.stream.listen(_onAuthState);
    _guardSub = _companyGuardCubit.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _authBloc;
  final CompanyGuardCubit _companyGuardCubit;
  final NotificationsCubit _notificationsCubit;
  late final StreamSubscription<AuthState> _authSub;

  StreamSubscription<dynamic>? _guardSub;
  int? _lastGuardRefreshUserId;

  void _onAuthState(AuthState state) {
    if (state is AuthAuthenticated) {
      final guardState = _companyGuardCubit.state;
      final alreadyResolvedForUser =
          _lastGuardRefreshUserId == state.user.id &&
              guardState is! CompanyGuardInitial;
      if (!alreadyResolvedForUser) {
        _lastGuardRefreshUserId = state.user.id;
        _companyGuardCubit.refresh(state.user.id);
      }
      _notificationsCubit.connectAndSync();
    } else if (state is AuthUnauthenticated) {
      _lastGuardRefreshUserId = null;
      _companyGuardCubit.reset();
      _notificationsCubit.disconnect();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _guardSub?.cancel();
    super.dispose();
  }
}
