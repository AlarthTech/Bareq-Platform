import '../constants/api_constants.dart';

/// Builds an absolute URL for API-relative paths (e.g. `/Uploads/...`).
String? resolveApiUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final p = path.trim();
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (p.startsWith('/')) return '${ApiConstants.baseUrl}$p';
  return '${ApiConstants.baseUrl}/$p';
}
