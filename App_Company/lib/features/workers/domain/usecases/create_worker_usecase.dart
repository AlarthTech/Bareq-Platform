import '../entities/worker_entity.dart';
import '../repositories/worker_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CreateWorkerUseCase {
  final WorkerRepository repository;
  
  CreateWorkerUseCase(this.repository);
  
  Future<Either<Failure, WorkerEntity>> call(CreateWorkerParams params) async {
    return await repository.createWorker(
      companyId: params.companyId,
      fullName: params.fullName,
      nationalityId: params.nationalityId,
      age: params.age,
      experienceYears: params.experienceYears,
      isAvailable: params.isAvailable,
      isActive: params.isActive,
      profileImage: params.profileImage,
      healthCertificate: params.healthCertificate,
      healthCertificateExpiryDate: params.healthCertificateExpiryDate,
      languagesIds: params.languagesIds,
    );
  }
}

class CreateWorkerParams extends Equatable {
  final int companyId;
  final String fullName;
  final int nationalityId;
  final int age;
  final int experienceYears;
  final bool isAvailable;
  final bool isActive;
  final String? profileImage;
  final String? healthCertificate;
  final DateTime? healthCertificateExpiryDate;
  final String languagesIds;
  
  const CreateWorkerParams({
    required this.companyId,
    required this.fullName,
    required this.nationalityId,
    required this.age,
    required this.experienceYears,
    required this.isAvailable,
    required this.isActive,
    this.profileImage,
    this.healthCertificate,
    this.healthCertificateExpiryDate,
    required this.languagesIds,
  });
  
  @override
  List<Object?> get props => [
    companyId,
    fullName,
    nationalityId,
    age,
    experienceYears,
    isAvailable,
    isActive,
    profileImage,
    healthCertificate,
    healthCertificateExpiryDate,
    languagesIds,
  ];
}
