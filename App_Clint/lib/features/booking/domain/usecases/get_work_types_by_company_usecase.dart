import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../entities/work_type.dart';
import '../repositories/booking_repository.dart';

/// Use case for getting work types by company ID
class GetWorkTypesByCompanyUseCase {
  final BookingRepository repository;

  GetWorkTypesByCompanyUseCase(this.repository);

  Future<Either<Failure, List<WorkType>>> call(int companyId) async {
    try {
      final workTypes = await repository.getWorkTypesByCompany(companyId);
      return Right(workTypes);
    } on NetworkFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
