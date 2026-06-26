import '../entities/worker_work_type_assignment_entity.dart';
import '../repositories/work_type_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class GetWorkerWorkTypesUseCase {
  final WorkTypeRepository repository;

  GetWorkerWorkTypesUseCase(this.repository);

  Future<Either<Failure, List<WorkerWorkTypeAssignmentEntity>>> call(int workerId) async {
    return repository.getWorkerWorkTypes(workerId);
  }
}
