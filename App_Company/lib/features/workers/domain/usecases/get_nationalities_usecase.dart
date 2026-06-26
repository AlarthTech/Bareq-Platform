import '../entities/nationality_entity.dart';
import '../repositories/worker_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class GetNationalitiesUseCase {
  final WorkerRepository repository;
  
  GetNationalitiesUseCase(this.repository);
  
  Future<Either<Failure, List<NationalityEntity>>> call() async {
    return await repository.getNationalities();
  }
}
