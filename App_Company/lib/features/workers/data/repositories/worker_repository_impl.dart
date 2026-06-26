import '../../domain/repositories/worker_repository.dart';
import '../../domain/entities/worker_entity.dart';
import '../../domain/entities/nationality_entity.dart';
import '../../domain/entities/language_entity.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../datasources/worker_remote_datasource.dart';
import 'package:dartz/dartz.dart';
import 'dart:typed_data';

class WorkerRepositoryImpl implements WorkerRepository {
  final WorkerRemoteDataSource remoteDataSource;
  
  WorkerRepositoryImpl(this.remoteDataSource);
  
  @override
  Future<Either<Failure, PagedResult<WorkerEntity>>> getWorkersByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  }) async {
    try {
      final page = await remoteDataSource.getWorkersByCompany(
        companyId,
        pagination: pagination,
      );
      return Right(
        PagedResult<WorkerEntity>(
          items: page.items.map((m) => m.toEntity()).toList(),
          page: page.page,
          pageSize: page.pageSize,
          totalCount: page.totalCount,
          totalPages: page.totalPages,
          hasNextPage: page.hasNextPage,
          hasPreviousPage: page.hasPreviousPage,
        ),
      );
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
  
  @override
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
  }) async {
    try {
      final worker = await remoteDataSource.createWorker(
        companyId: companyId,
        fullName: fullName,
        nationalityId: nationalityId,
        age: age,
        experienceYears: experienceYears,
        isAvailable: isAvailable,
        isActive: isActive,
        profileImage: profileImage,
        healthCertificate: healthCertificate,
        healthCertificateExpiryDate: healthCertificateExpiryDate,
        languagesIds: languagesIds,
      );
      return Right(worker.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
  
  @override
  Future<Either<Failure, List<NationalityEntity>>> getNationalities() async {
    try {
      final nationalities = await remoteDataSource.getNationalities();
      return Right(nationalities.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
  
  @override
  Future<Either<Failure, List<LanguageEntity>>> getAllLanguages() async {
    try {
      final languages = await remoteDataSource.getAllLanguages();
      return Right(languages.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateWorker({
    required int workerId,
    required String fullName,
    required int nationalityId,
    required int age,
    required int experienceYears,
    String? healthCertificateURL,
    DateTime? healthCertificateExpiryDate,
    required String languagesIds,
  }) async {
    try {
      await remoteDataSource.updateWorker(
        workerId: workerId,
        fullName: fullName,
        nationalityId: nationalityId,
        age: age,
        experienceYears: experienceYears,
        healthCertificateURL: healthCertificateURL,
        healthCertificateExpiryDate: healthCertificateExpiryDate,
        languagesIds: languagesIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, WorkerEntity>> uploadHealthCertificate({
    required int workerId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    try {
      final worker = await remoteDataSource.uploadHealthCertificate(
        workerId: workerId,
        fileName: fileName,
        filePath: filePath,
        bytes: bytes,
      );
      return Right(worker.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}
