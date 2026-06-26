import '../entities/maid.dart';
import '../repositories/home_repository.dart';

/// Use case for getting available maids
/// Encapsulates business logic for this specific operation
class GetAvailableMaidsUseCase {
  final HomeRepository repository;

  GetAvailableMaidsUseCase(this.repository);

  Future<List<Maid>> call({DateTime? selectedDate}) async {
    return await repository.getAvailableMaidsToday(selectedDate: selectedDate);
  }
}






