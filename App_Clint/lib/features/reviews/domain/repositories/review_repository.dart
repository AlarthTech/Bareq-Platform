import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, Review>> createReview({
    required int bookingId,
    required int workerId,
    required int rating,
    String? comment,
  });

  Future<Either<Failure, void>> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
  });

  Future<Either<Failure, void>> deleteReview(int reviewId);

  Future<Either<Failure, PagedResult<Review>>> getReviewsByWorker(
    int workerId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PagedResult<Review>>> getReviewsByBooking(
    int bookingId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Review>> getReviewById(int id);
}
