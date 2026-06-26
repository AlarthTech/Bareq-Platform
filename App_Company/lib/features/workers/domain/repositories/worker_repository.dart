import '../entities/worker_entity.dart';
import '../entities/nationality_entity.dart';
import '../entities/language_entity.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'dart:typed_data';

abstract class WorkerRepository {
  Future<Either<Failure, PagedResult<WorkerEntity>>> getWorkersByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  });
  Future<Either<Failure, WorkerEntity>> createWorker({
    required int companyId,
    required String fullName,
    required int nationalityId,
    required int age,
    required int experienceYears,
    required bool isAvailable,
    required bool isActive,
    String? profileImage,
    String? healthCertificate,
    DateTime? healthCertificateExpiryDate,
    required String languagesIds,
  });
  Future<Either<Failure, List<NationalityEntity>>> getNationalities();
  Future<Either<Failure, List<LanguageEntity>>> getAllLanguages();
  Future<Either<Failure, WorkerEntity>> uploadHealthCertificate({
    required int workerId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  });
  Future<Either<Failure, void>> updateWorker({
    required int workerId,
    required String fullName,
    required int nationalityId,
    required int age,
    required int experienceYears,
    String? healthCertificateURL,
    DateTime? healthCertificateExpiryDate,
    required String languagesIds,
  });
}
