import '../../domain/entities/city.dart';

/// City model for data layer
/// Handles serialization/deserialization from API responses
class CityModel extends City {
  const CityModel({
    required super.id,
    required super.name,
    super.code,
    required super.isActive,
  });

  /// Factory constructor to create CityModel from JSON
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert CityModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
    };
  }
}

