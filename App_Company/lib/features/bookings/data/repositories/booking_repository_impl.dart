import '../../domain/repositories/booking_repository.dart';
import '../../domain/entities/booking_entity.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../datasources/booking_remote_datasource.dart';
import 'package:dartz/dartz.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PagedResult<BookingEntity>>> getBookingsByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  }) async {
    try {
      final page = await remoteDataSource.getBookingsByCompany(
        companyId,
        pagination: pagination,
      );
      return Right(
        PagedResult<BookingEntity>(
          items: page.items.map((m) => m.toEntity()).toList(),
          page: page.page,
          pageSize: page.pageSize,
          totalCount: page.totalCount,
          totalPages: page.totalPages,
          hasNextPage: page.hasNextPage,
          hasPreviousPage: page.hasPreviousPage,
        ),
      );
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(int bookingId) async {
    try {
      final booking = await remoteDataSource.getBookingById(bookingId);
      return Right(booking.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(
    int bookingId,
    int statusValue, {
    String? rejectionReason,
  }) async {
    try {
      await remoteDataSource.updateBookingStatus(
        bookingId,
        statusValue,
        rejectionReason: rejectionReason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}
