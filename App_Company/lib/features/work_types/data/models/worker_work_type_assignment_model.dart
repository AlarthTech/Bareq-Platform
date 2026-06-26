import '../../domain/entities/worker_work_type_assignment_entity.dart';
import '../../../../core/utils/date_formatter.dart';

class WorkerWorkTypeAssignmentModel extends WorkerWorkTypeAssignmentEntity {
  const WorkerWorkTypeAssignmentModel({
    required super.id,
    required super.workerId,
    required super.workerName,
    required super.workTypeId,
    required super.workTypeName,
    required super.startTime,
    required super.endTime,
    required super.isOvernight,
    required super.price,
    super.monthlyPrice,
    super.createdAt,
  });

  factory WorkerWorkTypeAssignmentModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return WorkerWorkTypeAssignmentModel(
      id: json['id'] as int,
      workerId: json['workerId'] as int? ?? 0,
      workerName: json['workerName'] as String? ?? '',
      workTypeId: json['workTypeId'] as int? ?? 0,
      workTypeName: json['workTypeName'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isOvernight: json['isOvernight'] as bool? ?? false,
      price: toDouble(json['price']),
      monthlyPrice: json['monthlyPrice'] != null ? toDouble(json['monthlyPrice']) : null,
      createdAt: json['createdAt'] != null
          ? DateFormatter.parseDate(json['createdAt'] as String)
          : null,
    );
  }

  WorkerWorkTypeAssignmentEntity toEntity() {
    return WorkerWorkTypeAssignmentEntity(
      id: id,
      workerId: workerId,
      workerName: workerName,
      workTypeId: workTypeId,
      workTypeName: workTypeName,
      startTime: startTime,
      endTime: endTime,
      isOvernight: isOvernight,
      price: price,
      monthlyPrice: monthlyPrice,
      createdAt: createdAt,
    );
  }
}
