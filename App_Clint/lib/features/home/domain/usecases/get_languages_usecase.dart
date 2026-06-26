import '../entities/language.dart';
import '../repositories/home_repository.dart';

/// Use case for getting all languages
/// Encapsulates business logic for this specific operation
class GetLanguagesUseCase {
  final HomeRepository repository;

  GetLanguagesUseCase(this.repository);

  Future<List<Language>> call() async {
    return await repository.getAllLanguages();
  }
}

