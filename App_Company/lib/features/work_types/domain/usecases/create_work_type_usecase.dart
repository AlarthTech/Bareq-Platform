import '../entities/work_type_entity.dart';
import '../repositories/work_type_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CreateWorkTypeUseCase {
  final WorkTypeRepository repository;

  CreateWorkTypeUseCase(this.repository);

  Future<Either<Failure, WorkTypeEntity>> call(CreateWorkTypeParams params) async {
    return repository.createWorkType(
      name: params.name,
      companyId: params.companyId,
      isMonthly: params.isMonthly,
      price: params.price,
      startTime: params.startTime,
      endTime: params.endTime,
      isOvernight: params.isOvernight,
    );
  }
}

class CreateWorkTypeParams extends Equatable {
  final String name;
  final int companyId;
  final bool isMonthly;
  final double price;
  final String? startTime;
  final String? endTime;
  final bool isOvernight;

  const CreateWorkTypeParams({
    required this.name,
    required this.companyId,
    required this.isMonthly,
    required this.price,
    this.startTime,
    this.endTime,
    this.isOvernight = false,
  });

  @override
  List<Object?> get props => [
        name,
        companyId,
        isMonthly,
        price,
        startTime,
        endTime,
        isOvernight,
      ];
}
