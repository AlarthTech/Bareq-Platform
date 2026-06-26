import '../entities/city_entity.dart';
import '../repositories/company_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class GetAllCitiesUseCase {
  final CompanyRepository repository;
  
  GetAllCitiesUseCase(this.repository);
  
  Future<Either<Failure, List<CityEntity>>> call() async {
    return await repository.getAllCities();
  }
}
