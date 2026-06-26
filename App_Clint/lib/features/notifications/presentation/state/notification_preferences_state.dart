import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_preferences.dart';

sealed class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState();

  @override
  List<Object?> get props => [];
}

class NotificationPreferencesInitial extends NotificationPreferencesState {
  const NotificationPreferencesInitial();
}

class NotificationPreferencesLoading extends NotificationPreferencesState {
  const NotificationPreferencesLoading();
}

class NotificationPreferencesLoaded extends NotificationPreferencesState {
  const NotificationPreferencesLoaded(this.preferences);

  final NotificationPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}

class NotificationPreferencesError extends NotificationPreferencesState {
  const NotificationPreferencesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
