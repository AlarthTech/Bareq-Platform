import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';
import 'package:dartz/dartz.dart';

class GetUnreadCountUseCase {
  GetUnreadCountUseCase(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, int>> call() => repository.getUnreadCount();
}
