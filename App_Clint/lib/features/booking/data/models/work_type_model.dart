import '../../domain/entities/work_type.dart';

/// WorkType model for data layer
/// Handles serialization/deserialization from API responses
class WorkTypeModel extends WorkType {
  const WorkTypeModel({
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
    required super.createdAt,
  });

  /// Factory constructor to create WorkTypeModel from JSON
  factory WorkTypeModel.fromJson(Map<String, dynamic> json) {
    return WorkTypeModel(
      id: json['id'] as int,
      workerId: json['workerId'] as int,
      workerName: json['workerName'] as String? ?? '',
      workTypeId: json['workTypeId'] as int,
      workTypeName: json['workTypeName'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isOvernight: json['isOvernight'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble(),
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  /// Convert WorkTypeModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'workerName': workerName,
      'workTypeId': workTypeId,
      'workTypeName': workTypeName,
      'startTime': startTime,
      'endTime': endTime,
      'isOvernight': isOvernight,
      'price': price,
      'monthlyPrice': monthlyPrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
