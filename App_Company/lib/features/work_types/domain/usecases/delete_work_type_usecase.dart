import '../repositories/work_type_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class DeleteWorkTypeUseCase {
  final WorkTypeRepository repository;
  
  DeleteWorkTypeUseCase(this.repository);
  
  Future<Either<Failure, void>> call(int workTypeId) async {
    return await repository.deleteWorkType(workTypeId);
  }
}
