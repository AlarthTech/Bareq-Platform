import '../../domain/entities/company.dart';
import '../../domain/repositories/companies_repository.dart';
import '../models/company_model.dart';
import '../datasources/companies_remote_datasource.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/pagination_constants.dart';

class CompaniesRepositoryImpl implements CompaniesRepository {
  final CompaniesRemoteDataSource remoteDataSource;

  CompaniesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Company>> getAllCompanies() async {
    try {
      final all = <Company>[];
      var page = PaginationConstants.defaultPage;
      var hasNext = true;

      while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
        final paged = await remoteDataSource.getAllCompaniesPaginated(
          page: page,
          pageSize: PaginationConstants.defaultPageSize,
        );
        all.addAll(
          paged.items.map((json) => CompanyModel.fromJson(json)),
        );
        hasNext = paged.hasNextPage;
        page++;
      }
      return all;
    } on NetworkFailure {
      return [];
    } on ServerFailure {
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Company> getCompanyById(int id) async {
    try {
      final companyJson = await remoteDataSource.getCompanyById(id);
      return CompanyModel.fromJson(companyJson);
    } on NetworkFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } catch (_) {
      throw NetworkFailure('Unexpected error loading company');
    }
  }
}
