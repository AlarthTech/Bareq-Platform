import '../../domain/entities/nationality_entity.dart';

class NationalityModel extends NationalityEntity {
  const NationalityModel({
    required super.id,
    required super.name,
    required super.isActive,
  });
  
  factory NationalityModel.fromJson(Map<String, dynamic> json) {
    return NationalityModel(
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
  
  NationalityEntity toEntity() {
    return NationalityEntity(
      id: id,
      name: name,
      isActive: isActive,
    );
  }
}
