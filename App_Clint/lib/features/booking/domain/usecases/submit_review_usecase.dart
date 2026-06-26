import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/review_request.dart';
import '../repositories/booking_repository.dart';

/// Use case that submits a customer review for a completed booking
class SubmitReviewUseCase {
  final BookingRepository repository;

  SubmitReviewUseCase(this.repository);

  Future<Either<Failure, void>> call(ReviewRequest reviewRequest) {
    return repository.submitReview(reviewRequest);
  }
}
