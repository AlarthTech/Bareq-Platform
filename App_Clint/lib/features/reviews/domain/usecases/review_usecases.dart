import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class CreateReviewUseCase {
  CreateReviewUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Either<Failure, Review>> call({
    required int bookingId,
    required int workerId,
    required int rating,
    String? comment,
  }) {
    return _repository.createReview(
      bookingId: bookingId,
      workerId: workerId,
      rating: rating,
      comment: comment,
    );
  }
}

class UpdateReviewUseCase {
  UpdateReviewUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Either<Failure, void>> call({
    required int reviewId,
    int? rating,
    String? comment,
  }) {
    return _repository.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
    );
  }
}

class DeleteReviewUseCase {
  DeleteReviewUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Either<Failure, void>> call(int reviewId) {
    return _repository.deleteReview(reviewId);
  }
}

class GetReviewsByWorkerUseCase {
  GetReviewsByWorkerUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Either<Failure, PagedResult<Review>>> call(
    int workerId, {
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getReviewsByWorker(
      workerId,
      page: page,
      pageSize: pageSize,
    );
  }
}

class GetReviewsByBookingUseCase {
  GetReviewsByBookingUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Either<Failure, PagedResult<Review>>> call(
    int bookingId, {
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getReviewsByBooking(
      bookingId,
      page: page,
      pageSize: pageSize,
    );
  }
}

class GetReviewByIdUseCase {
  GetReviewByIdUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Either<Failure, Review>> call(int id) {
    return _repository.getReviewById(id);
  }
}

class HasReviewForBookingUseCase {
  HasReviewForBookingUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Either<Failure, bool>> call(int bookingId) async {
    final result = await _repository.getReviewsByBooking(
      bookingId,
      page: 1,
      pageSize: 1,
    );
    return result.fold(
      Left.new,
      (paged) => Right(paged.totalCount > 0),
    );
  }
}
