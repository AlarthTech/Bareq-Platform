import '../../domain/entities/language.dart';

/// Language model for data layer
/// Handles serialization/deserialization from API responses
class LanguageModel extends Language {
  const LanguageModel({
    required super.id,
    required super.name,
    super.code,
    required super.isActive,
  });

  /// Factory constructor to create LanguageModel from JSON
  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String,
      code: json['code'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert LanguageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'isActive': isActive,
    };
  }
}

