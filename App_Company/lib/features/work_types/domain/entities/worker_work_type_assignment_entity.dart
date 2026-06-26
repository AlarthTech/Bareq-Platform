import 'package:equatable/equatable.dart';

class WorkerWorkTypeAssignmentEntity extends Equatable {
  final int id;
  final int workerId;
  final String workerName;
  final int workTypeId;
  final String workTypeName;
  final String startTime;
  final String endTime;
  final bool isOvernight;
  final double price;
  final double? monthlyPrice;
  final DateTime? createdAt;

  const WorkerWorkTypeAssignmentEntity({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.workTypeId,
    required this.workTypeName,
    required this.startTime,
    required this.endTime,
    required this.isOvernight,
    required this.price,
    this.monthlyPrice,
    this.createdAt,
  });

  double get displayPrice => monthlyPrice ?? price;

  @override
  List<Object?> get props => [
        id,
        workerId,
        workerName,
        workTypeId,
        workTypeName,
        startTime,
        endTime,
        isOvernight,
        price,
        monthlyPrice,
        createdAt,
      ];
}
