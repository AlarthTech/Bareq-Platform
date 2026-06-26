import '../entities/maid.dart';
import '../repositories/home_repository.dart';

class GetFavoriteMaidsUseCase {
  final HomeRepository repository;

  GetFavoriteMaidsUseCase(this.repository);

  Future<List<Maid>> call(
    Set<String> favoriteIds, {
    DateTime? selectedDate,
  }) {
    return repository.getFavoriteMaids(favoriteIds, selectedDate: selectedDate);
  }
}
