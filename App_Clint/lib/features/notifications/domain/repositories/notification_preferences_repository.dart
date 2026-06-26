import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/notification_preferences.dart';

abstract class NotificationPreferencesRepository {
  NotificationPreferences get current;

  Stream<NotificationPreferences> watch();

  Future<Either<Failure, NotificationPreferences>> load();

  Future<Either<Failure, NotificationPreferences>> setNotificationsEnabled(
    bool enabled,
  );
}
