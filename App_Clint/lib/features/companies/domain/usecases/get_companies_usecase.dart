import '../entities/company.dart';
import '../repositories/companies_repository.dart';

/// Use case for getting all companies
class GetCompaniesUseCase {
  final CompaniesRepository repository;

  GetCompaniesUseCase(this.repository);

  Future<List<Company>> call() async {
    return await repository.getAllCompanies();
  }
}






