import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetNotificationsParams extends Equatable {
  const GetNotificationsParams({this.page = 1, this.pageSize = 20});

  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [page, pageSize];
}

class GetNotificationsUseCase {
  GetNotificationsUseCase(this.repository);

  final NotificationRepository repository;

  Future<Either<Failure, PagedResult<NotificationEntity>>> call(
    GetNotificationsParams params,
  ) {
    return repository.getNotifications(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
