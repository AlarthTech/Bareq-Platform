import '../../../../core/network/paged_result.dart';
import '../entities/maid.dart';
import '../repositories/home_repository.dart';

class GetAvailableMaidsPageUseCase {
  final HomeRepository repository;

  GetAvailableMaidsPageUseCase(this.repository);

  Future<PagedResult<Maid>> call({
    DateTime? selectedDate,
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getAvailableMaidsPage(
      selectedDate: selectedDate,
      page: page,
      pageSize: pageSize,
    );
  }
}
