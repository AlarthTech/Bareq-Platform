import '../entities/company_entity.dart';
import '../repositories/company_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateCompanyUseCase {
  UpdateCompanyUseCase(this.repository);

  final CompanyRepository repository;

  Future<Either<Failure, CompanyEntity>> call(UpdateCompanyParams params) {
    return repository.updateCompany(
      companyId: params.companyId,
      name: params.name,
      address: params.address,
      commercialRegNo: params.commercialRegNo,
      commercialRegisterURL: params.commercialRegisterURL,
      email: params.email,
      cityId: params.cityId,
      experienceYears: params.experienceYears,
      description: params.description,
    );
  }
}

class UpdateCompanyParams extends Equatable {
  const UpdateCompanyParams({
    required this.companyId,
    required this.name,
    this.address,
    this.commercialRegNo,
    this.commercialRegisterURL,
    required this.email,
    required this.cityId,
    this.experienceYears = 0,
    this.description,
  });

  final int companyId;
  final String name;
  final String? address;
  final String? commercialRegNo;
  final String? commercialRegisterURL;
  final String email;
  final int cityId;
  final int experienceYears;
  final String? description;

  @override
  List<Object?> get props => [
        companyId,
        name,
        address,
        commercialRegNo,
        commercialRegisterURL,
        email,
        cityId,
        experienceYears,
        description,
      ];
}
