import '../../domain/entities/service_category.dart';

/// Service category model for data layer
class ServiceCategoryModel extends ServiceCategory {
  const ServiceCategoryModel({
    required super.id,
    required super.name,
    required super.icon,
  });

  /// Factory constructor to create ServiceCategoryModel from JSON
  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
    );
  }

  /// Convert ServiceCategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}






