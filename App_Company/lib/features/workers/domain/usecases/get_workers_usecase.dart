import '../entities/worker_entity.dart';
import '../repositories/worker_repository.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetWorkersParams extends Equatable {
  final int companyId;
  final PaginationParams pagination;

  const GetWorkersParams({
    required this.companyId,
    this.pagination = const PaginationParams(),
  });

  @override
  List<Object> get props => [companyId, pagination];
}

class GetWorkersUseCase {
  final WorkerRepository repository;

  GetWorkersUseCase(this.repository);

  Future<Either<Failure, PagedResult<WorkerEntity>>> call(
    GetWorkersParams params,
  ) async {
    return repository.getWorkersByCompany(
      params.companyId,
      pagination: params.pagination,
    );
  }
}
