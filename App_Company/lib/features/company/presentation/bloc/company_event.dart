import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();
  
  @override
  List<Object?> get props => [];
}

class GetMyCompanyEvent extends CompanyEvent {
  const GetMyCompanyEvent(this.userId, {this.silent = false});

  final int userId;
  final bool silent;

  @override
  List<Object> get props => [userId, silent];
}

class CreateCompanyEvent extends CompanyEvent {
  final String name;
  final String? address;
  final String? commercialRegNo;
  final String phone;
  final String email;
  final int ownerUserId;
  final int cityId;
  final int experienceYears;
  final String? description;

  const CreateCompanyEvent({
    required this.name,
    this.address,
    this.commercialRegNo,
    required this.phone,
    required this.email,
    required this.ownerUserId,
    required this.cityId,
    this.experienceYears = 0,
    this.description,
  });

  @override
  List<Object?> get props => [
        name,
        address,
        commercialRegNo,
        phone,
        email,
        ownerUserId,
        cityId,
        experienceYears,
        description,
      ];
}

class SelectActiveCompanyEvent extends CompanyEvent {
  const SelectActiveCompanyEvent(this.companyId);

  final int companyId;

  @override
  List<Object> get props => [companyId];
}

class UpdateCompanyEvent extends CompanyEvent {
  const UpdateCompanyEvent({
    required this.userId,
    required this.companyId,
    required this.name,
    this.address,
    this.commercialRegNo,
    this.commercialRegisterURL,
    required this.email,
    required this.cityId,
    this.experienceYears = 0,
    this.description,
  });

  final int userId;
  final int companyId;
  final String name;
  final String? address;
  final String? commercialRegNo;
  final String? commercialRegisterURL;
  final String email;
  final int cityId;
  final int experienceYears;
  final String? description;

  @override
  List<Object?> get props => [
        userId,
        companyId,
        name,
        address,
        commercialRegNo,
        commercialRegisterURL,
        email,
        cityId,
        experienceYears,
        description,
      ];
}

class UploadCommercialRegisterEvent extends CompanyEvent {
  const UploadCommercialRegisterEvent({
    required this.companyId,
    required this.fileName,
    this.filePath,
    this.bytes,
  });

  final int companyId;
  final String fileName;
  final String? filePath;
  final Uint8List? bytes;

  @override
  List<Object?> get props => [companyId, fileName, filePath, bytes];
}

class GetAllCitiesEvent extends CompanyEvent {
  const GetAllCitiesEvent();
}
