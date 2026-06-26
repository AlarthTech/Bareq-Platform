import '../../domain/entities/maid.dart';

/// Maid model for data layer
/// Handles serialization/deserialization from API responses
class MaidModel extends Maid {
  const MaidModel({
    required super.id,
    required super.name,
    required super.avatarUrl,
    required super.rating,
    super.reviewCount = 0,
    required super.experienceYears,
    required super.isAvailableToday,
    super.nextAvailableDate,
    super.closestAvailableDate,
    super.availabilityLabel,
    super.availableDate,
    required super.specialties,
    super.languages = const [],
    super.companyId,
    super.companyName,
    super.companyRating,
    super.companyLocation,
    super.nationality,
    super.age,
    super.hasHealthCertificate,
    super.healthCertificateExpiryDate,
  });

  /// Factory constructor to create MaidModel from JSON
  /// Supports both old API format and new Workers API format
  factory MaidModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseExpiryDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (_) {
        return null;
      }
    }

    DateTime? parseAvailabilityDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) {
        return DateTime(value.year, value.month, value.day);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      try {
        final parsed = DateTime.parse(text);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        return null;
      }
    }

    // Parse languages from workers API format (e.g., "AC,EN" or "1,2")
    List<String> parseLanguages(dynamic languagesData) {
      if (languagesData == null) return [];
      
      if (languagesData is List) {
        return languagesData.map((e) => e.toString()).toList();
      }
      
      if (languagesData is String) {
        if (languagesData.isEmpty) return [];
        return languagesData.split(',').map((e) => e.trim()).toList();
      }
      
      return [];
    }

    // Check if this is the Workers API format (has fullName and companyId)
    final isWorkersFormat = json.containsKey('fullName') && json.containsKey('companyId');

    if (isWorkersFormat) {
      // Workers API format
      final id = json['id']?.toString() ?? '';
      final fullName = json['fullName'] as String? ?? '';
      final profileImage =
          (json['profileImage'] ?? json['profile_image'])?.toString() ?? '';
      final isAvailable = json['isAvailable'] as bool? ?? false;
      final experienceYears = json['experienceYears'] as int? ?? 0;
      final companyName = json['companyName'] as String?;
      final nationalityName = json['nationalityName'] as String?;
      final age = json['age'] as int?;
      final healthCertificate = json['healthCertificate'] as String?;
      final healthCertificateExpiryDate = json['healthCertificateExpiryDate'] as String?;
      final languagesIds = json['languagesIds'];

      return MaidModel(
        id: id,
        name: fullName,
        avatarUrl: profileImage,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount:
            (json['reviewCount'] as num?)?.toInt() ??
            (json['reviewsCount'] as num?)?.toInt() ??
            0,
        experienceYears: experienceYears,
        isAvailableToday: isAvailable,
        nextAvailableDate: parseAvailabilityDate(
          json['nextAvailableDate'] ??
              json['nextAvailableDay'] ??
              json['nearestAvailableDate'],
        ),
        specialties: [], // Workers API doesn't provide specialties
        languages: parseLanguages(languagesIds),
        companyId: json['companyId']?.toString(),
        companyName: companyName,
        companyRating: null, // Workers API doesn't provide company rating
        companyLocation: json['companyLocation'] as String? ??
            json['company_location'] as String?,
        nationality: nationalityName,
        age: age,
        hasHealthCertificate: healthCertificate != null && healthCertificate.isNotEmpty,
        healthCertificateExpiryDate: parseExpiryDate(healthCertificateExpiryDate),
      );
    } else {
      // Old API format
      return MaidModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? json['profileImage'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['review_count'] as int? ?? 0,
        experienceYears: json['experience_years'] as int? ?? json['experienceYears'] as int? ?? 0,
        isAvailableToday: json['is_available_today'] as bool? ?? json['isAvailable'] as bool? ?? false,
        nextAvailableDate: parseAvailabilityDate(
          json['next_available_date'] ??
              json['nextAvailableDate'] ??
              json['nearestAvailableDate'],
        ),
        specialties: (json['specialties'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        languages: parseLanguages(json['languages'] ?? json['languagesIds']),
        companyId: json['company_id']?.toString() ?? json['companyId']?.toString(),
        companyName: json['company_name'] as String? ?? json['companyName'] as String?,
        companyRating: (json['company_rating'] as num?)?.toDouble(),
        companyLocation: json['company_location'] as String?,
        nationality: json['nationality'] as String? ?? json['nationalityName'] as String?,
        age: json['age'] as int?,
        hasHealthCertificate: json['has_health_certificate'] as bool? ?? 
            (json['healthCertificate'] != null && (json['healthCertificate'] as String).isNotEmpty),
        healthCertificateExpiryDate: parseExpiryDate(
          json['health_certificate_expiry_date'] as String? ?? 
          json['healthCertificateExpiryDate'] as String?,
        ),
      );
    }
  }

  /// Convert MaidModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'rating': rating,
      'review_count': reviewCount,
      'experience_years': experienceYears,
      'is_available_today': isAvailableToday,
      'specialties': specialties,
      'languages': languages,
      'company_name': companyName,
      'company_rating': companyRating,
      'company_location': companyLocation,
      'nationality': nationality,
      'age': age,
      'has_health_certificate': hasHealthCertificate,
      'health_certificate_expiry_date': healthCertificateExpiryDate?.toIso8601String(),
    };
  }
}

