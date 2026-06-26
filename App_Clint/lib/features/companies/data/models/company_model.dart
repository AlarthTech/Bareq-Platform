import '../../domain/entities/company.dart';

/// Company model for data layer
/// Handles serialization/deserialization from API responses
class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.logoUrl,
    required super.description,
    required super.rating,
    super.reviewCount = 0,
    required super.location,
    super.cityName,
    required super.phoneNumber,
    required super.totalMaids,
    required super.services,
    super.isVerified = false,
    super.yearsInBusiness = 0,
    super.isBoosted = false,
    super.monthlyAccommodationFee,
  });

  static double? _parseMonthlyFee(Map<String, dynamic> json) {
    for (final key in [
      'monthlyAccommodationFee',
      'monthly_accommodation_fee',
      'accommodationFee',
      'accommodation_fee',
      'monthlyResidencyFee',
    ]) {
      final v = json[key];
      if (v is num) return v.toDouble();
    }
    return null;
  }

  /// Factory constructor to create CompanyModel from JSON
  /// Supports both old API format and new Companies API format
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    // Check if this is the new Companies API format (has cityName and address)
    final isNewFormat = json.containsKey('cityName') && json.containsKey('address');

    if (isNewFormat) {
      // New Companies API format
      // Combine address and cityName for location
      final address = json['address'] as String? ?? '';
      final cityName = json['cityName'] as String? ?? '';
      final location = address.isNotEmpty && cityName.isNotEmpty
          ? '$address, $cityName'
          : (address.isNotEmpty ? address : cityName);
      
      return CompanyModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        logoUrl: '', // Companies API doesn't provide logo
        description: json['description'] as String? ?? '',
        rating: 0.0, // Companies API doesn't provide rating
        reviewCount: 0, // Companies API doesn't provide review count
        location: location,
        cityName: cityName.isNotEmpty ? cityName : null,
        phoneNumber: json['phone'] as String? ?? '',
        totalMaids: 0, // Will be calculated from workers
        services: [], // Companies API doesn't provide services list
        isVerified: json['isVerified'] as bool? ?? false,
        yearsInBusiness: json['experienceYears'] as int? ?? 0,
        isBoosted: false, // Companies API doesn't provide isBoosted
        monthlyAccommodationFee: _parseMonthlyFee(json),
      );
    } else {
      // Old API format
      return CompanyModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        logoUrl: json['logo_url'] as String? ?? '',
        description: json['description'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['review_count'] as int? ?? 0,
        location: json['location'] as String? ?? '',
        cityName: json['cityName'] as String? ?? json['city_name'] as String?,
        phoneNumber: json['phone_number'] as String? ?? json['phone'] as String? ?? '',
        totalMaids: json['total_maids'] as int? ?? 0,
        services: (json['services'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
        yearsInBusiness: json['years_in_business'] as int? ?? json['experienceYears'] as int? ?? 0,
        isBoosted: json['is_boosted'] as bool? ?? false,
        monthlyAccommodationFee: _parseMonthlyFee(json),
      );
    }
  }

  /// Convert CompanyModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'description': description,
      'rating': rating,
      'review_count': reviewCount,
      'location': location,
      'phone_number': phoneNumber,
      'total_maids': totalMaids,
      'services': services,
      'is_verified': isVerified,
      'years_in_business': yearsInBusiness,
      'is_boosted': isBoosted,
    };
  }
}

