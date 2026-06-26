import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Opens the booking location in the platform maps app.
Future<bool> openBookingInMaps({
  required double lat,
  required double lng,
  String? label,
}) async {
  final encodedLabel = label != null && label.trim().isNotEmpty
      ? Uri.encodeComponent(label.trim())
      : null;

  final Uri uri;
  if (Platform.isIOS || Platform.isMacOS) {
    uri = Uri.parse(
      encodedLabel != null
          ? 'https://maps.apple.com/?ll=$lat,$lng&q=$encodedLabel'
          : 'https://maps.apple.com/?ll=$lat,$lng',
    );
  } else {
    uri = Uri.parse(
      encodedLabel != null
          ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encodedLabel'
          : 'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  }

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
