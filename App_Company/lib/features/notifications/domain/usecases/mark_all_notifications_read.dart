import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';
import 'package:dartz/dartz.dart';

class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, void>> call() => repository.markAllAsRead();
}
