/// Utility functions for image handling
class ImageUtils {
  /// Check if a string is a valid URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    // Check if it starts with http:// or https://
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    
    // Valid URL must have a scheme (http/https) and a host
    return uri.hasScheme && 
           (uri.scheme == 'http' || uri.scheme == 'https') &&
           uri.hasAuthority &&
           uri.host.isNotEmpty;
  }
}

