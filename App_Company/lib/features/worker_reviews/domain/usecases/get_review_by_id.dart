import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/worker_reviews_repository.dart';
import 'package:dartz/dartz.dart';

class GetReviewByIdUseCase {
  GetReviewByIdUseCase(this.repository);

  final WorkerReviewsRepository repository;

  Future<Either<Failure, Review>> call(int reviewId) {
    return repository.getReviewById(reviewId);
  }
}
