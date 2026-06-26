import '../repositories/work_type_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class AssignWorkTypeToWorkerUseCase {
  final WorkTypeRepository repository;

  AssignWorkTypeToWorkerUseCase(this.repository);

  Future<Either<Failure, void>> call(AssignWorkTypeToWorkerParams params) async {
    return repository.assignWorkTypeToWorker(
      workerId: params.workerId,
      workTypeId: params.workTypeId,
    );
  }
}

class AssignWorkTypeToWorkerParams extends Equatable {
  final int workerId;
  final int workTypeId;

  const AssignWorkTypeToWorkerParams({
    required this.workerId,
    required this.workTypeId,
  });

  @override
  List<Object> get props => [workerId, workTypeId];
}
