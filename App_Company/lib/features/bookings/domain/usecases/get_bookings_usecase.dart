import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetBookingsParams extends Equatable {
  final int companyId;
  final PaginationParams pagination;

  const GetBookingsParams({
    required this.companyId,
    this.pagination = const PaginationParams(),
  });

  @override
  List<Object> get props => [companyId, pagination];
}

class GetBookingsUseCase {
  final BookingRepository repository;

  GetBookingsUseCase(this.repository);

  Future<Either<Failure, PagedResult<BookingEntity>>> call(
    GetBookingsParams params,
  ) async {
    return repository.getBookingsByCompany(
      params.companyId,
      pagination: params.pagination,
    );
  }
}
