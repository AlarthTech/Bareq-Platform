import 'package:equatable/equatable.dart';

/// Base failure class for domain errors
/// All failures must extend this class
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

/// Server-related failures
class ServerFailure extends Failure {
  final int? statusCode;
  
  const ServerFailure(super.message, [this.statusCode]);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Authorization / permission failures (HTTP 403)
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message =
        'You do not have permission for this action. Please contact support if you need help.',
  ]);
}

/// Booking slot conflict (HTTP 409) — generic
class ConflictFailure extends Failure {
  const ConflictFailure([
    super.message =
        'هذه العاملة غير متاحة في هذا الموعد، يرجى اختيار عاملة أخرى أو موعد مختلف.',
  ]);
}

/// Create-booking conflict (HTTP 409 ProblemDetails.detail from CleaningHouse API).
class BookingConflictFailure extends Failure {
  const BookingConflictFailure(super.message);

  @override
  List<Object> get props => [message];
}

/// Rate limiting (HTTP 429)
class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message =
        'تم إرسال عدد كبير من الطلبات، يرجى المحاولة بعد قليل.',
  ]);
}

/// Resource not found (HTTP 404)
class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'The requested resource was not found.',
  ]);
}

/// Wallet payment disabled by server configuration.
class WalletDisabledFailure extends Failure {
  const WalletDisabledFailure([
    super.message = 'Wallet payment is currently unavailable.',
  ]);
}

/// Wallet balance too low for booking payment (HTTP 400).
class InsufficientWalletBalanceFailure extends Failure {
  final double walletBalance;
  final double requiredAmount;

  InsufficientWalletBalanceFailure({
    required this.walletBalance,
    required this.requiredAmount,
    String? message,
  }) : super(
          message ??
              'Insufficient wallet balance. Please charge your wallet to continue.',
        );

  @override
  List<Object> get props => [message, walletBalance, requiredAmount];
}

/// No active bank account configured for transfers (HTTP 404).
class NoBankAccountConfiguredFailure extends Failure {
  const NoBankAccountConfiguredFailure([
    super.message =
        'Bank transfer is not available. No active bank account is configured.',
  ]);
}

