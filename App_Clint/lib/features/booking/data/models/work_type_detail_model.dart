import '../../domain/entities/work_type_detail.dart';

/// WorkTypeDetail model for data layer
/// Handles serialization/deserialization from API responses
class WorkTypeDetailModel extends WorkTypeDetail {
  const WorkTypeDetailModel({
    required super.id,
    required super.name,
    required super.companyId,
    required super.companyName,
    required super.startTime,
    required super.endTime,
    required super.isOvernight,
    required super.price,
    required super.isActive,
    required super.createdAt,
  });

  /// Factory constructor to create WorkTypeDetailModel from JSON
  factory WorkTypeDetailModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty || dateString == 'string') {
        return null;
      }
      try {
        return DateTime.parse(dateString);
      } catch (_) {
        return null;
      }
    }

    return WorkTypeDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      companyId: (json['companyId'] as num?)?.toInt() ?? 0,
      companyName: json['companyName'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isOvernight: json['isOvernight'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt'] as String?) ?? DateTime.now(),
    );
  }

  /// Convert WorkTypeDetailModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'companyId': companyId,
      'companyName': companyName,
      'startTime': startTime,
      'endTime': endTime,
      'isOvernight': isOvernight,
      'price': price,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
