import 'package:equatable/equatable.dart';

abstract class WorkTypeEvent extends Equatable {
  const WorkTypeEvent();

  @override
  List<Object?> get props => [];
}

class GetWorkTypesEvent extends WorkTypeEvent {
  final int companyId;

  const GetWorkTypesEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadMoreWorkTypesEvent extends WorkTypeEvent {
  final int companyId;

  const LoadMoreWorkTypesEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateWorkTypeEvent extends WorkTypeEvent {
  final String name;
  final int companyId;
  final bool isMonthly;
  final double price;
  final String? startTime;
  final String? endTime;
  final bool isOvernight;

  const CreateWorkTypeEvent({
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

class UpdateWorkTypeEvent extends WorkTypeEvent {
  final int workTypeId;
  final String name;
  final bool isMonthly;
  final double price;
  final bool isActive;
  final String? startTime;
  final String? endTime;
  final bool isOvernight;

  const UpdateWorkTypeEvent({
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

class DeleteWorkTypeEvent extends WorkTypeEvent {
  final int workTypeId;

  const DeleteWorkTypeEvent(this.workTypeId);

  @override
  List<Object> get props => [workTypeId];
}
