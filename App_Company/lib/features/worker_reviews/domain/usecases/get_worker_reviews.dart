import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/worker_reviews_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetWorkerReviewsParams extends Equatable {
  const GetWorkerReviewsParams({
    required this.workerId,
    this.page = 1,
    this.pageSize = 20,
  });

  final int workerId;
  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [workerId, page, pageSize];
}

class GetWorkerReviewsUseCase {
  GetWorkerReviewsUseCase(this.repository);

  final WorkerReviewsRepository repository;

  Future<Either<Failure, PagedResult<Review>>> call(
    GetWorkerReviewsParams params,
  ) {
    return repository.getWorkerReviews(
      params.workerId,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
