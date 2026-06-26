import '../../domain/entities/company_entity.dart';
import '../../../../core/utils/date_formatter.dart';

class CompanyModel extends CompanyEntity {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.address,
    required super.commercialRegNo,
    required super.phone,
    super.email,
    required super.ownerUserId,
    required super.cityId,
    super.cityName,
    required super.experienceYears,
    super.description,
    super.isVerified,
    super.commercialRegisterUrl,
    super.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      commercialRegNo: json['commercialRegNo'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      ownerUserId: json['ownerUserId'] as int? ?? 0,
      cityId: json['cityId'] as int? ?? 0,
      cityName: json['cityName'] as String?,
      experienceYears: json['experienceYears'] as int? ?? 0,
      description: json['description'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      commercialRegisterUrl: json['commercialRegisterURL'] as String?,
      createdAt: json['createdAt'] != null
          ? DateFormatter.parseDate(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'commercialRegNo': commercialRegNo,
      'phone': phone,
      'email': email,
      'ownerUserId': ownerUserId,
      'cityId': cityId,
      'cityName': cityName,
      'experienceYears': experienceYears,
      'description': description,
      'isVerified': isVerified,
      'commercialRegisterURL': commercialRegisterUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  CompanyEntity toEntity() {
    return CompanyEntity(
      id: id,
      name: name,
      address: address,
      commercialRegNo: commercialRegNo,
      phone: phone,
      email: email,
      ownerUserId: ownerUserId,
      cityId: cityId,
      cityName: cityName,
      experienceYears: experienceYears,
      description: description,
      isVerified: isVerified,
      commercialRegisterUrl: commercialRegisterUrl,
      createdAt: createdAt,
    );
  }
}
