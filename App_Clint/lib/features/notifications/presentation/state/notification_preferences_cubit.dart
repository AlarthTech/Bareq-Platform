import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/notification_preferences_usecases.dart';
import 'notification_preferences_state.dart';

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    required LoadNotificationPreferencesUseCase loadPreferencesUseCase,
    required SetNotificationsEnabledUseCase setNotificationsEnabledUseCase,
    required WatchNotificationPreferencesUseCase watchPreferencesUseCase,
  })  : _loadPreferencesUseCase = loadPreferencesUseCase,
        _setNotificationsEnabledUseCase = setNotificationsEnabledUseCase,
        _watchPreferencesUseCase = watchPreferencesUseCase,
        super(const NotificationPreferencesInitial());

  final LoadNotificationPreferencesUseCase _loadPreferencesUseCase;
  final SetNotificationsEnabledUseCase _setNotificationsEnabledUseCase;
  final WatchNotificationPreferencesUseCase _watchPreferencesUseCase;

  StreamSubscription<dynamic>? _watchSubscription;

  Future<void> load() async {
    emit(const NotificationPreferencesLoading());
    final result = await _loadPreferencesUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationPreferencesError(failure.message)),
      (preferences) => emit(NotificationPreferencesLoaded(preferences)),
    );
  }

  void startWatching() {
    _watchSubscription ??=
        _watchPreferencesUseCase().listen((preferences) {
      if (isClosed) return;
      emit(NotificationPreferencesLoaded(preferences));
    });
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final previous = state;
    if (previous is NotificationPreferencesLoaded) {
      emit(
        NotificationPreferencesLoaded(
          previous.preferences.copyWith(notificationsEnabled: enabled),
        ),
      );
    }

    final result = await _setNotificationsEnabledUseCase(enabled);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (previous is NotificationPreferencesLoaded) {
          emit(NotificationPreferencesLoaded(previous.preferences));
        }
      },
      (preferences) => emit(NotificationPreferencesLoaded(preferences)),
    );
  }

  @override
  Future<void> close() async {
    await _watchSubscription?.cancel();
    return super.close();
  }
}
