import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/company.dart';
import '../repositories/companies_repository.dart';

/// Use case for getting a company by ID
/// Encapsulates business logic for this specific operation
class GetCompanyByIdUseCase {
  final CompaniesRepository repository;

  GetCompanyByIdUseCase(this.repository);

  Future<Either<Failure, Company>> call(int id) async {
    try {
      final company = await repository.getCompanyById(id);
      return Right(company);
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

