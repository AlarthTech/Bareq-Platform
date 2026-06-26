import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';
import 'package:dartz/dartz.dart';

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, void>> call(int notificationId) {
    return repository.markAsRead(notificationId);
  }
}
