import 'dart:async';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../datasources/notification_preferences_local_datasource.dart';

class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  NotificationPreferencesRepositoryImpl(this._local);

  final NotificationPreferencesLocalDataSource _local;

  NotificationPreferences _current = NotificationPreferences.defaults;
  final _streamController =
      StreamController<NotificationPreferences>.broadcast();

  @override
  NotificationPreferences get current => _current;

  @override
  Stream<NotificationPreferences> watch() => _streamController.stream;

  @override
  Future<Either<Failure, NotificationPreferences>> load() async {
    try {
      _current = await _local.read();
      _streamController.add(_current);
      return Right(_current);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferences>> setNotificationsEnabled(
    bool enabled,
  ) async {
    try {
      final updated = _current.copyWith(notificationsEnabled: enabled);
      _current = await _local.write(updated);
      _streamController.add(_current);
      return Right(_current);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
