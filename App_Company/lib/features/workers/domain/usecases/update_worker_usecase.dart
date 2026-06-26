import '../repositories/worker_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateWorkerUseCase {
  UpdateWorkerUseCase(this.repository);

  final WorkerRepository repository;

  Future<Either<Failure, void>> call(UpdateWorkerParams params) {
    return repository.updateWorker(
      workerId: params.workerId,
      fullName: params.fullName,
      nationalityId: params.nationalityId,
      age: params.age,
      experienceYears: params.experienceYears,
      healthCertificateURL: params.healthCertificateURL,
      healthCertificateExpiryDate: params.healthCertificateExpiryDate,
      languagesIds: params.languagesIds,
    );
  }
}

class UpdateWorkerParams extends Equatable {
  const UpdateWorkerParams({
    required this.workerId,
    required this.fullName,
    required this.nationalityId,
    required this.age,
    required this.experienceYears,
    this.healthCertificateURL,
    this.healthCertificateExpiryDate,
    required this.languagesIds,
  });

  final int workerId;
  final String fullName;
  final int nationalityId;
  final int age;
  final int experienceYears;
  final String? healthCertificateURL;
  final DateTime? healthCertificateExpiryDate;
  final String languagesIds;

  @override
  List<Object?> get props => [
        workerId,
        fullName,
        nationalityId,
        age,
        experienceYears,
        healthCertificateURL,
        healthCertificateExpiryDate,
        languagesIds,
      ];
}
