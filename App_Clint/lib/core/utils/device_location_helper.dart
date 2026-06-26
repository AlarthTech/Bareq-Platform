import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resolves the device GPS position for map pickers.
class DeviceLocationHelper {
  DeviceLocationHelper._();

  static Future<({LatLng? position, String? errorKey})> getCurrentLatLng() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (position: null, errorKey: 'locationServiceDisabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return (position: null, errorKey: 'locationPermissionDenied');
    }
    if (permission == LocationPermission.deniedForever) {
      return (position: null, errorKey: 'locationPermissionDeniedForever');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return (
        position: LatLng(position.latitude, position.longitude),
        errorKey: null,
      );
    } catch (_) {
      return (position: null, errorKey: 'locationUnavailable');
    }
  }
}
