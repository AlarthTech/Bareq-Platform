import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/booking_report.dart';
import '../repositories/booking_report_repository.dart';

class UpdateBookingReportStatusUseCase {
  UpdateBookingReportStatusUseCase(this._repository);

  final BookingReportRepository _repository;

  Future<Either<Failure, BookingReport>> call(
    UpdateBookingReportStatusParams params,
  ) {
    return _repository.updateBookingReportStatus(
      id: params.id,
      status: params.status,
      adminResolutionNotes: params.adminResolutionNotes,
    );
  }
}

class UpdateBookingReportStatusParams extends Equatable {
  const UpdateBookingReportStatusParams({
    required this.id,
    required this.status,
    this.adminResolutionNotes,
  });

  final int id;
  final int status;
  final String? adminResolutionNotes;

  @override
  List<Object?> get props => [id, status, adminResolutionNotes];
}
