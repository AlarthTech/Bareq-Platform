import '../../domain/entities/language_entity.dart';

class LanguageModel extends LanguageEntity {
  const LanguageModel({
    required super.id,
    required super.name,
    required super.isActive,
  });
  
  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
    };
  }
  
  LanguageEntity toEntity() {
    return LanguageEntity(
      id: id,
      name: name,
      isActive: isActive,
    );
  }
}
