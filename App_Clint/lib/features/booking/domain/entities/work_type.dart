import 'package:equatable/equatable.dart';

/// WorkType entity representing a worker's work type in the domain layer
class WorkType extends Equatable {
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
  final DateTime createdAt;

  const WorkType({
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
    required this.createdAt,
  });

  bool get isMonthly {
    final normalizedName = workTypeName.trim().toLowerCase();
    return normalizedName.contains('month') ||
        normalizedName.contains('شهري') ||
        normalizedName.contains('شهرية');
  }

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
