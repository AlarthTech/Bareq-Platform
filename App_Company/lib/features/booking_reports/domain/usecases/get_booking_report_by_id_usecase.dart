import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/booking_report.dart';
import '../repositories/booking_report_repository.dart';

class GetBookingReportByIdUseCase {
  GetBookingReportByIdUseCase(this._repository);

  final BookingReportRepository _repository;

  Future<Either<Failure, BookingReport>> call(int id) {
    return _repository.getBookingReportById(id);
  }
}
