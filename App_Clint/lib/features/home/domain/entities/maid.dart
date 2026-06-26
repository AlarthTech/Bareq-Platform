import 'package:equatable/equatable.dart';

/// Maid entity representing a maid in the domain layer
/// This is part of Clean Architecture - domain layer knows nothing about data sources
class Maid extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final double rating;
  final int reviewCount; // Number of reviews
  final int experienceYears;
  /// Availability for the date used in the workers API query (not always calendar today).
  final bool isAvailableToday;
  /// Next date the worker can be booked, when not available on the query date.
  final DateTime? nextAvailableDate;
  /// Earliest date on or after calendar today when the worker can be booked.
  final DateTime? closestAvailableDate;
  /// Server-computed label (e.g. "Available Today", "Available on Jun 15, 2026").
  final String? availabilityLabel;
  /// Selected/query date for the available-workers endpoint.
  final DateTime? availableDate;
  final List<String> specialties; // e.g., ['Daily Cleaning', 'Deep Cleaning']
  final List<String> languages; // e.g., ['Arabic', 'English', 'French']

  // Company Information
  final String? companyId;
  final String? companyName;
  final double? companyRating;
  final String? companyLocation;

  // Personal Information
  final String? nationality;
  final int? age;
  final bool hasHealthCertificate;
  final DateTime? healthCertificateExpiryDate;

  const Maid({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    this.reviewCount = 0,
    required this.experienceYears,
    required this.isAvailableToday,
    this.nextAvailableDate,
    this.closestAvailableDate,
    this.availabilityLabel,
    this.availableDate,
    required this.specialties,
    this.languages = const [],
    this.companyId,
    this.companyName,
    this.companyRating,
    this.companyLocation,
    this.nationality,
    this.age,
    this.hasHealthCertificate = false,
    this.healthCertificateExpiryDate,
  });

  Maid copyWith({
    double? rating,
    int? reviewCount,
    bool? isAvailableToday,
    DateTime? nextAvailableDate,
    bool clearNextAvailableDate = false,
    DateTime? closestAvailableDate,
    bool clearClosestAvailableDate = false,
    String? availabilityLabel,
    bool clearAvailabilityLabel = false,
    DateTime? availableDate,
    bool clearAvailableDate = false,
    String? companyLocation,
  }) {
    return Maid(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears,
      isAvailableToday: isAvailableToday ?? this.isAvailableToday,
      nextAvailableDate: clearNextAvailableDate
          ? null
          : (nextAvailableDate ?? this.nextAvailableDate),
      closestAvailableDate: clearClosestAvailableDate
          ? null
          : (closestAvailableDate ?? this.closestAvailableDate),
      availabilityLabel: clearAvailabilityLabel
          ? null
          : (availabilityLabel ?? this.availabilityLabel),
      availableDate: clearAvailableDate
          ? null
          : (availableDate ?? this.availableDate),
      specialties: specialties,
      languages: languages,
      companyId: companyId,
      companyName: companyName,
      companyRating: companyRating,
      companyLocation: companyLocation ?? this.companyLocation,
      nationality: nationality,
      age: age,
      hasHealthCertificate: hasHealthCertificate,
      healthCertificateExpiryDate: healthCertificateExpiryDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    avatarUrl,
    rating,
    reviewCount,
    experienceYears,
    isAvailableToday,
    nextAvailableDate,
        closestAvailableDate,
        availabilityLabel,
        availableDate,
        specialties,
    languages,
    companyId,
    companyName,
    companyRating,
    companyLocation,
    nationality,
    age,
    hasHealthCertificate,
    healthCertificateExpiryDate,
  ];
}
