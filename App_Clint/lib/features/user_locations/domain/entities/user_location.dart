import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final int id;
  final int userId;
  final String locationName;
  final double lat;
  final double lng;
  final DateTime createdAt;

  const UserLocation({
    required this.id,
    required this.userId,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, locationName, lat, lng, createdAt];
}
