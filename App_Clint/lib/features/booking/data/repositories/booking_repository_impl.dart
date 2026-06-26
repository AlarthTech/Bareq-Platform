import '../../domain/entities/work_type.dart';
import '../../domain/entities/work_type_detail.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/review_request.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/work_type_model.dart';
import '../models/work_type_detail_model.dart';
import '../models/booking_model.dart';
import '../datasources/booking_remote_datasource.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paged_result.dart';
import '../../../../core/network/pagination_constants.dart';
import '../../../../core/utils/either.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  List<Booking> _mapBookings(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<List<WorkType>> getWorkerWorkTypes(int workerId) async {
    try {
      final workTypesJson = await remoteDataSource.getWorkerWorkTypes(workerId);
      return workTypesJson.map((json) => WorkTypeModel.fromJson(json)).toList();
    } on NetworkFailure {
      return [];
    } on ServerFailure {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WorkType>> getWorkTypesByCompany(int companyId) async {
    try {
      final workTypesJson =
          await remoteDataSource.getWorkTypesByCompany(companyId);
      return workTypesJson.map((json) => WorkTypeModel.fromJson(json)).toList();
    } on NetworkFailure {
      return [];
    } on ServerFailure {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Either<Failure, List<WorkTypeDetail>>> getAllWorkTypes() async {
    try {
      final workTypesJson = await remoteDataSource.getAllWorkTypes();
      final workTypes = workTypesJson
          .map((json) => WorkTypeDetailModel.fromJson(json))
          .toList();
      return Right(workTypes);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PagedResult<Booking>>> getUserBookingsPage(
    int userId, {
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final paged = await remoteDataSource.getUserBookingsPage(
        userId,
        page: page,
        pageSize: pageSize,
      );
      return Right(
        PagedResult<Booking>(
          items: _mapBookings(paged.items),
          page: paged.page,
          pageSize: paged.pageSize,
          totalCount: paged.totalCount,
          totalPages: paged.totalPages,
          hasNextPage: paged.hasNextPage,
          hasPreviousPage: paged.hasPreviousPage,
        ),
      );
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getUserBookings(int userId) async {
    final all = <Booking>[];
    var page = PaginationConstants.defaultPage;
    var hasNext = true;

    while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
      final result = await getUserBookingsPage(
        userId,
        page: page,
        pageSize: PaginationConstants.defaultPageSize,
      );
      Failure? failure;
      result.fold((f) => failure = f, (p) {
        all.addAll(p.items);
        hasNext = p.hasNextPage;
        page++;
      });
      if (failure != null) return Left(failure!);
    }
    return Right(all);
  }

  @override
  Future<Either<Failure, List<Booking>>> getCompanyBookings(int companyId) async {
    try {
      final all = <Booking>[];
      var page = PaginationConstants.defaultPage;
      var hasNext = true;

      while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
        final paged = await remoteDataSource.getCompanyBookingsPage(
          companyId,
          page: page,
          pageSize: PaginationConstants.defaultPageSize,
        );
        all.addAll(_mapBookings(paged.items));
        hasNext = paged.hasNextPage;
        page++;
      }
      return Right(all);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Booking>> createBooking(
    BookingRequest bookingRequest,
  ) async {
    try {
      final bookingJson = await remoteDataSource.createBooking(
        bookingRequest.toJson(),
      );
      return Right(BookingModel.fromJson(bookingJson));
    } on BookingConflictFailure catch (e) {
      return Left(e);
    } on ValidationFailure catch (e) {
      return Left(e);
    } on WalletDisabledFailure catch (e) {
      return Left(e);
    } on InsufficientWalletBalanceFailure catch (e) {
      return Left(e);
    } on AuthFailure catch (e) {
      return Left(e);
    } on RateLimitFailure catch (e) {
      return Left(e);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(
    int bookingId,
    int status, {
    String? rejectionReason,
  }) async {
    try {
      await remoteDataSource.updateBookingStatus(
        bookingId,
        status,
        rejectionReason: rejectionReason,
      );
      return const Right(null);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> confirmWorkerArrival(int bookingId) async {
    try {
      await remoteDataSource.confirmWorkerArrival(bookingId);
      return const Right(null);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> submitReview(
    ReviewRequest reviewRequest,
  ) async {
    try {
      await remoteDataSource.submitReview(reviewRequest.toJson());
      return const Right(null);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
