import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';
import '../models/create_review_request.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._remoteDataSource);

  final ReviewRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Review>> createReview({
    required int bookingId,
    required int workerId,
    required int rating,
    String? comment,
  }) async {
    try {
      final model = await _remoteDataSource.createReview(
        CreateReviewRequest(
          bookingId: bookingId,
          workerId: workerId,
          rating: rating,
          comment: comment,
        ),
      );
      return Right(model.toEntity());
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      await _remoteDataSource.updateReview(
        reviewId,
        UpdateReviewRequest(rating: rating, comment: comment),
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(int reviewId) async {
    try {
      await _remoteDataSource.deleteReview(reviewId);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<Review>>> getReviewsByWorker(
    int workerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final paged = await _remoteDataSource.getReviewsByWorker(
        workerId,
        page: page,
        pageSize: pageSize,
      );
      return Right(_mapPaged(paged));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<Review>>> getReviewsByBooking(
    int bookingId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final paged = await _remoteDataSource.getReviewsByBooking(
        bookingId,
        page: page,
        pageSize: pageSize,
      );
      return Right(_mapPaged(paged));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review>> getReviewById(int id) async {
    try {
      final model = await _remoteDataSource.getReviewById(id);
      return Right(model.toEntity());
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  PagedResult<Review> _mapPaged(PagedResult<ReviewModel> paged) {
    return PagedResult<Review>(
      items: paged.items.map((m) => m.toEntity()).toList(),
      page: paged.page,
      pageSize: paged.pageSize,
      totalCount: paged.totalCount,
      totalPages: paged.totalPages,
      hasNextPage: paged.hasNextPage,
      hasPreviousPage: paged.hasPreviousPage,
    );
  }
}
