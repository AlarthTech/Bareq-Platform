import '../repositories/booking_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateBookingStatusUseCase {
  final BookingRepository repository;

  UpdateBookingStatusUseCase(this.repository);

  Future<Either<Failure, void>> call(UpdateBookingStatusParams params) async {
    if (params.statusValue == AppConstants.statusRejected) {
      final r = params.rejectionReason?.trim() ?? '';
      if (r.isEmpty) {
        return const Left(ValidationFailure('يرجى إدخال سبب الرفض'));
      }
    }
    return repository.updateBookingStatus(
      params.bookingId,
      params.statusValue,
      rejectionReason: params.rejectionReason,
    );
  }
}

class UpdateBookingStatusParams extends Equatable {
  final int bookingId;
  final int statusValue;
  final String? rejectionReason;

  const UpdateBookingStatusParams({
    required this.bookingId,
    required this.statusValue,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [bookingId, statusValue, rejectionReason];
}
