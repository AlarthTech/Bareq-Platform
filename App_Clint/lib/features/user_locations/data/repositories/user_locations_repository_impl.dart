import '../../../../core/data/models/paged_result.dart';
import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/user_locations_repository.dart';
import '../datasources/user_locations_remote_datasource.dart';
import '../models/user_location_model.dart';

class UserLocationsRepositoryImpl implements UserLocationsRepository {
  UserLocationsRepositoryImpl(this.remoteDataSource);

  final UserLocationsRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<UserLocation>>> getMyLocations() async {
    try {
      final all = <UserLocation>[];
      var page = PaginationConstants.defaultPage;
      var hasNext = true;

      while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
        final paged = await remoteDataSource.getMyLocationsPage(
          page: page,
          pageSize: PaginationConstants.defaultPageSize,
        );
        all.addAll(
          paged.items.map((j) => UserLocationModel.fromJson(j)),
        );
        hasNext = paged.hasNextPage;
        page++;
      }
      return Right(all);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<UserLocation>>> getMyLocationsPage({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final paged = await remoteDataSource.getMyLocationsPage(
        page: page,
        pageSize: pageSize,
      );
      return Right(
        PagedResult<UserLocation>(
          items: paged.items.map((j) => UserLocationModel.fromJson(j)).toList(),
          page: paged.page,
          pageSize: paged.pageSize,
          totalCount: paged.totalCount,
          totalPages: paged.totalPages,
          hasNextPage: paged.hasNextPage,
          hasPreviousPage: paged.hasPreviousPage,
        ),
      );
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLocation>> create({
    required String locationName,
    required double lat,
    required double lng,
  }) async {
    try {
      final json = await remoteDataSource.create({
        'locationName': locationName,
        'lat': lat,
        'lng': lng,
      });
      return Right(UserLocationModel.fromJson(json));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLocation>> update({
    required int id,
    String? locationName,
    double? lat,
    double? lng,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (locationName != null) body['locationName'] = locationName;
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;
      final json = await remoteDataSource.update(id, body);
      return Right(UserLocationModel.fromJson(json));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await remoteDataSource.delete(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}
