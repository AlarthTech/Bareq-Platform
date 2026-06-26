import '../entities/language_entity.dart';
import '../repositories/worker_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class GetLanguagesUseCase {
  final WorkerRepository repository;
  
  GetLanguagesUseCase(this.repository);
  
  Future<Either<Failure, List<LanguageEntity>>> call() async {
    return await repository.getAllLanguages();
  }
}
