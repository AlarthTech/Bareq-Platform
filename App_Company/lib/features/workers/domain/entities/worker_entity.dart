import 'package:equatable/equatable.dart';

class WorkerEntity extends Equatable {
  final int id;
  final String fullName;
  final String nationalityName;
  final int? nationalityId;
  final int age;
  final int experienceYears;
  final bool isActive;
  final bool isAvailable;
  final String? profileImage;
  final String? healthCertificate;
  /// Relative path from API, e.g. `/Uploads/HealthCertificates/...`
  final String? healthCertificateURL;
  final DateTime? healthCertificateExpiryDate;
  final String? languagesIds; // Comma-separated IDs
  final String? companyName;
  final int? companyId;
  final DateTime? createdAt;
  
  const WorkerEntity({
    required this.id,
    required this.fullName,
    required this.nationalityName,
    this.nationalityId,
    required this.age,
    required this.experienceYears,
    required this.isActive,
    required this.isAvailable,
    this.profileImage,
    this.healthCertificate,
    this.healthCertificateURL,
    this.healthCertificateExpiryDate,
    this.languagesIds,
    this.companyName,
    this.companyId,
    this.createdAt,
  });
  
  @override
  List<Object?> get props => [
    id,
    fullName,
    nationalityName,
    nationalityId,
    age,
    experienceYears,
    isActive,
    isAvailable,
    profileImage,
    healthCertificate,
    healthCertificateURL,
    healthCertificateExpiryDate,
    languagesIds,
    companyName,
    companyId,
    createdAt,
  ];
}
