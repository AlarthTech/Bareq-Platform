import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_report.dart';
import '../repositories/booking_report_repository.dart';

class GetCompanyBookingReportsUseCase {
  GetCompanyBookingReportsUseCase(this._repository);

  final BookingReportRepository _repository;

  Future<Either<Failure, PagedResult<BookingReport>>> call(
    GetCompanyBookingReportsParams params,
  ) {
    return _repository.getCompanyBookingReports(
      filters: params.filters,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class GetCompanyBookingReportsParams extends Equatable {
  const GetCompanyBookingReportsParams({
    this.filters,
    this.page = 1,
    this.pageSize = 20,
  });

  final BookingReportFilters? filters;
  final int page;
  final int pageSize;

  @override
  List<Object?> get props => [filters, page, pageSize];
}
