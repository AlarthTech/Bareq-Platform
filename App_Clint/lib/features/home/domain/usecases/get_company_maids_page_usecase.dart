import '../../../../core/network/paged_result.dart';
import '../entities/maid.dart';
import '../repositories/home_repository.dart';

class GetCompanyMaidsPageUseCase {
  final HomeRepository repository;

  GetCompanyMaidsPageUseCase(this.repository);

  Future<PagedResult<Maid>> call(
    int companyId, {
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getCompanyMaidsPage(
      companyId,
      page: page,
      pageSize: pageSize,
    );
  }
}
