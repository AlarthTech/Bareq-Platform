import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/notification_category.dart';
import '../entities/notification_preferences.dart';
import '../repositories/notification_preferences_repository.dart';

class LoadNotificationPreferencesUseCase {
  LoadNotificationPreferencesUseCase(this._repository);

  final NotificationPreferencesRepository _repository;

  Future<Either<Failure, NotificationPreferences>> call() =>
      _repository.load();
}

class SetNotificationsEnabledUseCase {
  SetNotificationsEnabledUseCase(this._repository);

  final NotificationPreferencesRepository _repository;

  Future<Either<Failure, NotificationPreferences>> call(bool enabled) =>
      _repository.setNotificationsEnabled(enabled);
}

class WatchNotificationPreferencesUseCase {
  WatchNotificationPreferencesUseCase(this._repository);

  final NotificationPreferencesRepository _repository;

  Stream<NotificationPreferences> call() => _repository.watch();
}

class IsNotificationEnabledUseCase {
  IsNotificationEnabledUseCase(this._repository);

  final NotificationPreferencesRepository _repository;

  bool call(NotificationCategory category) =>
      _repository.current.isEnabled(category);
}
