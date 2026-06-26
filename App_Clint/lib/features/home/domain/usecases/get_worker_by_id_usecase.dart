import '../entities/maid.dart';
import '../repositories/home_repository.dart';

/// Loads a single worker profile by id for the worker details screen.
class GetWorkerByIdUseCase {
  GetWorkerByIdUseCase(this.repository);

  final HomeRepository repository;

  Future<Maid?> call(String workerId) => repository.getWorkerById(workerId);
}
