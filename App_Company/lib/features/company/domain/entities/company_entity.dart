import 'package:equatable/equatable.dart';

class CompanyEntity extends Equatable {
  final int id;
  final String name;
  final String address;
  final String commercialRegNo;
  final String phone;
  final String? email;
  final int ownerUserId;
  final int cityId;
  final String? cityName;
  final int experienceYears;
  final String? description;
  final bool isVerified;
  final String? commercialRegisterUrl;
  final DateTime? createdAt;

  const CompanyEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.commercialRegNo,
    required this.phone,
    this.email,
    required this.ownerUserId,
    required this.cityId,
    this.cityName,
    required this.experienceYears,
    this.description,
    this.isVerified = false,
    this.commercialRegisterUrl,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    commercialRegNo,
    phone,
    email,
    ownerUserId,
    cityId,
    cityName,
    experienceYears,
    description,
    isVerified,
    commercialRegisterUrl,
    createdAt,
  ];
}
