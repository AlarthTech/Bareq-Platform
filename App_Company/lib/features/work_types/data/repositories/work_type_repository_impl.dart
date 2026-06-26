import '../../domain/repositories/work_type_repository.dart';
import '../../domain/entities/work_type_entity.dart';
import '../../domain/entities/worker_work_type_assignment_entity.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../datasources/work_type_remote_datasource.dart';
import 'package:dartz/dartz.dart';

class WorkTypeRepositoryImpl implements WorkTypeRepository {
  final WorkTypeRemoteDataSource remoteDataSource;
  
  WorkTypeRepositoryImpl(this.remoteDataSource);
  
  @override
  Future<Either<Failure, PagedResult<WorkTypeEntity>>> getWorkTypesByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  }) async {
    try {
      final page = await remoteDataSource.getWorkTypesByCompany(
        companyId,
        pagination: pagination,
      );
      return Right(
        PagedResult<WorkTypeEntity>(
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
  Future<Either<Failure, WorkTypeEntity>> getWorkTypeById(int workTypeId) async {
    try {
      final workType = await remoteDataSource.getWorkTypeById(workTypeId);
      return Right(workType.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
  
  @override
  Future<Either<Failure, WorkTypeEntity>> createWorkType({
    required String name,
    required int companyId,
    required bool isMonthly,
    required double price,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  }) async {
    try {
      final workType = await remoteDataSource.createWorkType(
        name: name,
        companyId: companyId,
        isMonthly: isMonthly,
        price: price,
        startTime: startTime,
        endTime: endTime,
        isOvernight: isOvernight,
      );
      return Right(workType.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateWorkType({
    required int workTypeId,
    required String name,
    required bool isMonthly,
    required double price,
    required bool isActive,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  }) async {
    try {
      await remoteDataSource.updateWorkType(
        workTypeId: workTypeId,
        name: name,
        isMonthly: isMonthly,
        price: price,
        isActive: isActive,
        startTime: startTime,
        endTime: endTime,
        isOvernight: isOvernight,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteWorkType(int workTypeId) async {
    try {
      await remoteDataSource.deleteWorkType(workTypeId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> assignWorkTypeToWorker({
    required int workerId,
    required int workTypeId,
  }) async {
    try {
      await remoteDataSource.assignWorkTypeToWorker(
        workerId: workerId,
        workTypeId: workTypeId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Either<Failure, List<WorkerWorkTypeAssignmentEntity>>> getWorkerWorkTypes(
    int workerId,
  ) async {
    try {
      final list = await remoteDataSource.getWorkerWorkTypes(workerId);
      return Right(list.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}
