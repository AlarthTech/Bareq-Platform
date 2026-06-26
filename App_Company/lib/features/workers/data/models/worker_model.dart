import '../../domain/entities/worker_entity.dart';
import '../../../../core/utils/date_formatter.dart';

class WorkerModel extends WorkerEntity {
  const WorkerModel({
    required super.id,
    required super.fullName,
    required super.nationalityName,
    super.nationalityId,
    required super.age,
    required super.experienceYears,
    required super.isActive,
    required super.isAvailable,
    super.profileImage,
    super.healthCertificate,
    super.healthCertificateURL,
    super.healthCertificateExpiryDate,
    super.languagesIds,
    super.companyName,
    super.companyId,
    super.createdAt,
  });
  
  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      nationalityName: json['nationalityName'] as String? ?? '',
      nationalityId: json['nationalityId'] as int?,
      age: json['age'] as int? ?? 0,
      experienceYears: json['experienceYears'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      profileImage: json['profileImage'] as String?,
      healthCertificate: json['healthCertificate'] as String?,
      healthCertificateURL: json['healthCertificateURL'] as String?,
      healthCertificateExpiryDate: json['healthCertificateExpiryDate'] != null
          ? DateFormatter.parseDate(json['healthCertificateExpiryDate'] as String)
          : null,
      languagesIds: json['languagesIds'] as String?,
      companyName: json['companyName'] as String?,
      companyId: json['companyId'] as int?,
      createdAt: json['createdAt'] != null
          ? DateFormatter.parseDate(json['createdAt'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'nationalityName': nationalityName,
      'nationalityId': nationalityId,
      'age': age,
      'experienceYears': experienceYears,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'profileImage': profileImage,
      'healthCertificate': healthCertificate,
      'healthCertificateURL': healthCertificateURL,
      'healthCertificateExpiryDate': healthCertificateExpiryDate?.toIso8601String(),
      'languagesIds': languagesIds,
      'companyName': companyName,
      'companyId': companyId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  WorkerEntity toEntity() {
    return WorkerEntity(
      id: id,
      fullName: fullName,
      nationalityName: nationalityName,
      nationalityId: nationalityId,
      age: age,
      experienceYears: experienceYears,
      isActive: isActive,
      isAvailable: isAvailable,
      profileImage: profileImage,
      healthCertificate: healthCertificate,
      healthCertificateURL: healthCertificateURL,
      healthCertificateExpiryDate: healthCertificateExpiryDate,
      languagesIds: languagesIds,
      companyName: companyName,
      companyId: companyId,
      createdAt: createdAt,
    );
  }
}
