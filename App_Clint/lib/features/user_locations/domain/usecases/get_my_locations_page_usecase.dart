import '../../../../core/data/models/paged_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_location.dart';
import '../repositories/user_locations_repository.dart';

class GetMyLocationsPageUseCase {
  final UserLocationsRepository repository;

  GetMyLocationsPageUseCase(this.repository);

  Future<Either<Failure, PagedResult<UserLocation>>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getMyLocationsPage(page: page, pageSize: pageSize);
  }
}
