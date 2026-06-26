import '../../../../core/utils/calendar_date.dart';
import 'maid_model.dart';

/// Maps `WorkerCardDto` (v1) or legacy `/api/Workers/Available` worker JSON.
class WorkerCardModel extends MaidModel {
  const WorkerCardModel({
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
    super.hasHealthCertificate = false,
    super.healthCertificateExpiryDate,
  });

  factory WorkerCardModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) {
        return DateTime(value.year, value.month, value.day);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      try {
        return CalendarDate.parseFromApi(text);
      } catch (_) {
        return null;
      }
    }

    List<String> parseLanguages(dynamic languagesData) {
      if (languagesData == null) return [];
      if (languagesData is List) {
        return languagesData.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (languagesData is String) {
        if (languagesData.trim().isEmpty) return [];
        return languagesData.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final isAvailable = json['isAvailable'] as bool?;
    final isAvailableToday = json['isAvailableToday'] as bool?;

    return WorkerCardModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['fullName'])?.toString() ?? '',
      avatarUrl: (json['profileImageUrl'] ??
              json['profileImage'] ??
              json['profile_image'])
          ?.toString() ??
          '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount:
          (json['reviewCount'] as num?)?.toInt() ??
          (json['reviewsCount'] as num?)?.toInt() ??
          0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      isAvailableToday: isAvailableToday ?? isAvailable ?? false,
      nextAvailableDate: parseDate(json['nextAvailableDate']),
      availabilityLabel: json['availabilityLabel'] as String?,
      availableDate: parseDate(json['availableDate']),
      specialties: const [],
      languages: parseLanguages(
        json['languagesIds'] ?? json['languages'] ?? json['languageIds'],
      ),
      companyId: json['companyId']?.toString(),
      companyName: json['companyName'] as String?,
      companyLocation: json['companyLocation'] as String?,
      nationality: (json['nationalityName'] ?? json['nationality'])?.toString(),
      age: (json['age'] as num?)?.toInt(),
      hasHealthCertificate: json['healthCertificate'] != null &&
          json['healthCertificate'].toString().trim().isNotEmpty,
      healthCertificateExpiryDate: parseDate(
        json['healthCertificateExpiryDate'],
      ),
    );
  }
}
