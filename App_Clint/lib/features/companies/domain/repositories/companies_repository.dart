import '../entities/company.dart';

/// Companies repository interface
/// Defines the contract for fetching companies data
abstract class CompaniesRepository {
  /// Get all companies
  Future<List<Company>> getAllCompanies();

  /// Get company by ID
  Future<Company> getCompanyById(int id);
}






