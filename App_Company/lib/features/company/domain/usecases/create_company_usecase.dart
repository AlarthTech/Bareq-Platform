import '../entities/company_entity.dart';
import '../repositories/company_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CreateCompanyUseCase {
  CreateCompanyUseCase(this.repository);

  final CompanyRepository repository;

  Future<Either<Failure, CompanyEntity>> call(CreateCompanyParams params) {
    return repository.createCompany(
      name: params.name,
      address: params.address,
      commercialRegNo: params.commercialRegNo,
      phone: params.phone,
      email: params.email,
      ownerUserId: params.ownerUserId,
      cityId: params.cityId,
      experienceYears: params.experienceYears,
      description: params.description,
    );
  }
}

class CreateCompanyParams extends Equatable {
  final String name;
  final String? address;
  final String? commercialRegNo;
  final String phone;
  final String email;
  final int ownerUserId;
  final int cityId;
  final int experienceYears;
  final String? description;

  const CreateCompanyParams({
    required this.name,
    this.address,
    this.commercialRegNo,
    required this.phone,
    required this.email,
    required this.ownerUserId,
    required this.cityId,
    this.experienceYears = 0,
    this.description,
  });

  @override
  List<Object?> get props => [
        name,
        address,
        commercialRegNo,
        phone,
        email,
        ownerUserId,
        cityId,
        experienceYears,
        description,
      ];
}
