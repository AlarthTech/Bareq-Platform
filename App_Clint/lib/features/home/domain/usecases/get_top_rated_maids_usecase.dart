import '../entities/maid.dart';
import '../repositories/home_repository.dart';

/// Use case for getting top rated maids
class GetTopRatedMaidsUseCase {
  final HomeRepository repository;

  GetTopRatedMaidsUseCase(this.repository);

  Future<List<Maid>> call() async {
    return repository.getTopRatedMaids();
  }
}






