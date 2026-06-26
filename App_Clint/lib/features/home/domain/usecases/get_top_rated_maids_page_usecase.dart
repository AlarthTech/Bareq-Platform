import '../../../../core/network/paged_result.dart';
import '../entities/maid.dart';
import '../repositories/home_repository.dart';

class GetTopRatedMaidsPageUseCase {
  final HomeRepository repository;

  GetTopRatedMaidsPageUseCase(this.repository);

  Future<PagedResult<Maid>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getTopRatedMaidsPage(page: page, pageSize: pageSize);
  }
}
