import '../../../../core/error/failures.dart';

double? _parseAmount(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

Map<String, dynamic>? _asMap(dynamic body) {
  if (body is Map<String, dynamic>) return body;
  if (body is Map) return Map<String, dynamic>.from(body);
  return null;
}

/// Maps wallet-related 400 responses from booking create or wallet APIs.
Failure? parseWalletFailureFromBody(dynamic body) {
  final map = _asMap(body);
  if (map == null) return null;

  final message = map['message']?.toString().trim() ?? '';
  final lower = message.toLowerCase();

  if (lower.contains('wallet payment is currently unavailable') ||
      lower.contains('wallet payment is unavailable')) {
    return WalletDisabledFailure(
      message.isNotEmpty
          ? message
          : 'Wallet payment is currently unavailable.',
    );
  }

  final balance = _parseAmount(map['walletBalance']);
  final required = _parseAmount(map['requiredAmount']);
  if (balance != null && required != null) {
    return InsufficientWalletBalanceFailure(
      walletBalance: balance,
      requiredAmount: required,
      message: message.isNotEmpty
          ? message
          : 'Insufficient wallet balance. Please charge your wallet to continue.',
    );
  }

  if (lower.contains('insufficient wallet')) {
    return InsufficientWalletBalanceFailure(
      walletBalance: balance ?? 0,
      requiredAmount: required ?? 0,
      message: message,
    );
  }

  return null;
}
