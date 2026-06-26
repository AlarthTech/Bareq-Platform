import '../../../../core/network/paged_result.dart';
import '../entities/maid.dart';
import '../entities/service_category.dart';
import '../entities/language.dart';

/// Home repository interface
abstract class HomeRepository {
  /// Workers available on [selectedDate] (defaults to today on the server).
  Future<List<Maid>> getAvailableMaidsToday({DateTime? selectedDate});

  Future<PagedResult<Maid>> getAvailableMaidsPage({
    DateTime? selectedDate,
    int page = 1,
    int pageSize = 20,
  });

  Future<PagedResult<Maid>> getTopRatedMaidsPage({
    int page = 1,
    int pageSize = 20,
  });

  /// Highest-rated workers (first page).
  Future<List<Maid>> getTopRatedMaids();

  Future<PagedResult<Maid>> getCompanyMaidsPage(
    int companyId, {
    DateTime? selectedDate,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<Maid>> getFavoriteMaids(
    Set<String> favoriteIds, {
    DateTime? selectedDate,
  });

  Future<Maid?> getWorkerById(String workerId);

  Future<Maid?> findWorkerCardById(String workerId);

  Future<List<ServiceCategory>> getServiceCategories();

  Future<List<Language>> getAllLanguages();
}
