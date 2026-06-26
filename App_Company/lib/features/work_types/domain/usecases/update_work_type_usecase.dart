import '../repositories/work_type_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateWorkTypeUseCase {
  final WorkTypeRepository repository;

  UpdateWorkTypeUseCase(this.repository);

  Future<Either<Failure, void>> call(UpdateWorkTypeParams params) async {
    return repository.updateWorkType(
      workTypeId: params.workTypeId,
      name: params.name,
      isMonthly: params.isMonthly,
      price: params.price,
      isActive: params.isActive,
      startTime: params.startTime,
      endTime: params.endTime,
      isOvernight: params.isOvernight,
    );
  }
}

class UpdateWorkTypeParams extends Equatable {
  final int workTypeId;
  final String name;
  final bool isMonthly;
  final double price;
  final bool isActive;
  final String? startTime;
  final String? endTime;
  final bool isOvernight;

  const UpdateWorkTypeParams({
    required this.workTypeId,
    required this.name,
    required this.isMonthly,
    required this.price,
    required this.isActive,
    this.startTime,
    this.endTime,
    this.isOvernight = false,
  });

  @override
  List<Object?> get props => [
        workTypeId,
        name,
        isMonthly,
        price,
        isActive,
        startTime,
        endTime,
        isOvernight,
      ];
}
