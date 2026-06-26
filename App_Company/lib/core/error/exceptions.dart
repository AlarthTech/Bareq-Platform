class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  const ServerException(this.message, [this.statusCode]);
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  
  const CacheException(this.message);
}

class ValidationException implements Exception {
  final String message;
  
  const ValidationException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  
  const UnauthorizedException(this.message);
}

class ForbiddenException implements Exception {
  final String message;

  const ForbiddenException(this.message);
}

class RateLimitException implements Exception {
  final String message;

  const RateLimitException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  
  const NotFoundException(this.message);
}

class ActiveBookingsException implements Exception {
  final String message;

  const ActiveBookingsException(this.message);
}
