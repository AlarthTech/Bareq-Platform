import '../../domain/entities/user_location.dart';

class UserLocationModel extends UserLocation {
  const UserLocationModel({
    required super.id,
    required super.userId,
    required super.locationName,
    required super.lat,
    required super.lng,
    required super.createdAt,
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    DateTime? parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return UserLocationModel(
      id: parseInt(json['id']),
      userId: parseInt(json['userId']),
      locationName: json['locationName'] as String? ?? '',
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      createdAt: parseDate(json['createdAt'] as String?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'locationName': locationName,
    'lat': lat,
    'lng': lng,
  };

  Map<String, dynamic> toUpdateJson({
    String? locationName,
    double? lat,
    double? lng,
  }) {
    final m = <String, dynamic>{};
    if (locationName != null) m['locationName'] = locationName;
    if (lat != null) m['lat'] = lat;
    if (lng != null) m['lng'] = lng;
    return m;
  }
}
