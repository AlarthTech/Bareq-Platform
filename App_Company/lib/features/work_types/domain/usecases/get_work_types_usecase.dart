import '../entities/work_type_entity.dart';
import '../repositories/work_type_repository.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetWorkTypesParams extends Equatable {
  final int companyId;
  final PaginationParams pagination;

  const GetWorkTypesParams({
    required this.companyId,
    this.pagination = const PaginationParams(),
  });

  @override
  List<Object> get props => [companyId, pagination];
}

class GetWorkTypesUseCase {
  final WorkTypeRepository repository;

  GetWorkTypesUseCase(this.repository);

  Future<Either<Failure, PagedResult<WorkTypeEntity>>> call(
    GetWorkTypesParams params,
  ) async {
    return repository.getWorkTypesByCompany(
      params.companyId,
      pagination: params.pagination,
    );
  }
}
