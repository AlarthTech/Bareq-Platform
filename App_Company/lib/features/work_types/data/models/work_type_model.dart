import '../../domain/entities/work_type_entity.dart';

class WorkTypeModel extends WorkTypeEntity {
  const WorkTypeModel({
    required super.id,
    required super.name,
    super.startTime,
    super.endTime,
    super.isOvernight = false,
    required super.price,
    super.monthlyPrice,
    super.isMonthly = false,
    required super.companyId,
    super.isActive = true,
  });

  factory WorkTypeModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return WorkTypeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      isOvernight: json['isOvernight'] as bool? ?? false,
      price: toDouble(json['price']),
      monthlyPrice: json['monthlyPrice'] != null
          ? toDouble(json['monthlyPrice'])
          : null,
      isMonthly: json['isMonthly'] as bool? ?? false,
      companyId: (json['companyId'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'isOvernight': isOvernight,
      'price': price,
      'monthlyPrice': monthlyPrice,
      'isMonthly': isMonthly,
      'companyId': companyId,
      'isActive': isActive,
    };
  }

  WorkTypeEntity toEntity() {
    return WorkTypeEntity(
      id: id,
      name: name,
      startTime: startTime,
      endTime: endTime,
      isOvernight: isOvernight,
      price: price,
      monthlyPrice: monthlyPrice,
      isMonthly: isMonthly,
      companyId: companyId,
      isActive: isActive,
    );
  }
}
