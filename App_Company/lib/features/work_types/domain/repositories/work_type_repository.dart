import '../entities/work_type_entity.dart';
import '../entities/worker_work_type_assignment_entity.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class WorkTypeRepository {
  Future<Either<Failure, PagedResult<WorkTypeEntity>>> getWorkTypesByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  });
  Future<Either<Failure, WorkTypeEntity>> getWorkTypeById(int workTypeId);
  Future<Either<Failure, WorkTypeEntity>> createWorkType({
    required String name,
    required int companyId,
    required bool isMonthly,
    required double price,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  });
  Future<Either<Failure, void>> updateWorkType({
    required int workTypeId,
    required String name,
    required bool isMonthly,
    required double price,
    required bool isActive,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  });
  Future<Either<Failure, void>> deleteWorkType(int workTypeId);
  Future<Either<Failure, void>> assignWorkTypeToWorker({
    required int workerId,
    required int workTypeId,
  });
  Future<Either<Failure, List<WorkerWorkTypeAssignmentEntity>>> getWorkerWorkTypes(
    int workerId,
  );
}
