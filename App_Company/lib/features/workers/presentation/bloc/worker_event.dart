import 'package:equatable/equatable.dart';

abstract class WorkerEvent extends Equatable {
  const WorkerEvent();
  
  @override
  List<Object?> get props => [];
}

class GetWorkersEvent extends WorkerEvent {
  final int companyId;

  const GetWorkersEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadMoreWorkersEvent extends WorkerEvent {
  final int companyId;

  const LoadMoreWorkersEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateWorkerEvent extends WorkerEvent {
  final int companyId;
  final String fullName;
  final int nationalityId;
  final int age;
  final int experienceYears;
  final bool isAvailable;
  final bool isActive;
  final String? profileImage;
  final String? healthCertificate;
  final DateTime? healthCertificateExpiryDate;
  final String languagesIds;
  
  const CreateWorkerEvent({
    required this.companyId,
    required this.fullName,
    required this.nationalityId,
    required this.age,
    required this.experienceYears,
    required this.isAvailable,
    required this.isActive,
    this.profileImage,
    this.healthCertificate,
    this.healthCertificateExpiryDate,
    required this.languagesIds,
  });
  
  @override
  List<Object?> get props => [
    companyId,
    fullName,
    nationalityId,
    age,
    experienceYears,
    isAvailable,
    isActive,
    profileImage,
    healthCertificate,
    healthCertificateExpiryDate,
    languagesIds,
  ];
}

/// Loads nationalities and languages together for the add-worker form (single state).
class LoadWorkerFormLookupsEvent extends WorkerEvent {
  const LoadWorkerFormLookupsEvent();
}
