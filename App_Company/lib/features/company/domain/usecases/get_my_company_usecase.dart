import '../entities/company_entity.dart';
import '../repositories/company_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetMyCompanyUseCase {
  final CompanyRepository repository;
  
  GetMyCompanyUseCase(this.repository);
  
  Future<Either<Failure, List<CompanyEntity>>> call(int userId) async {
    return await repository.getMyCompany(userId);
  }
}
