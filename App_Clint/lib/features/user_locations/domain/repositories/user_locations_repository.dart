import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_location.dart';

abstract class UserLocationsRepository {
  Future<Either<Failure, List<UserLocation>>> getMyLocations();

  Future<Either<Failure, PagedResult<UserLocation>>> getMyLocationsPage({
    int page = 1,
    int pageSize = 20,
  });
  Future<Either<Failure, UserLocation>> create({
    required String locationName,
    required double lat,
    required double lng,
  });
  Future<Either<Failure, UserLocation>> update({
    required int id,
    String? locationName,
    double? lat,
    double? lng,
  });
  Future<Either<Failure, void>> delete(int id);
}
