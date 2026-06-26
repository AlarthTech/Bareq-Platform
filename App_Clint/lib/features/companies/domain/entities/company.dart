import 'package:equatable/equatable.dart';

/// Company entity representing a cleaning company in the domain layer
class Company extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final String location;
  final String? cityName;
  final String phoneNumber;
  final int totalMaids;
  final List<String> services; // Services offered
  final bool isVerified;
  final int yearsInBusiness;
  final bool isBoosted; // Featured/boosted companies
  /// Extra monthly residency/accommodation fee (LYD) for monthly worker bookings.
  final double? monthlyAccommodationFee;

  const Company({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.description,
    required this.rating,
    this.reviewCount = 0,
    required this.location,
    this.cityName,
    required this.phoneNumber,
    required this.totalMaids,
    required this.services,
    this.isVerified = false,
    this.yearsInBusiness = 0,
    this.isBoosted = false,
    this.monthlyAccommodationFee,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    logoUrl,
    description,
    rating,
    reviewCount,
    location,
    cityName,
    phoneNumber,
    totalMaids,
    services,
    isVerified,
    yearsInBusiness,
    isBoosted,
    monthlyAccommodationFee,
  ];
}
