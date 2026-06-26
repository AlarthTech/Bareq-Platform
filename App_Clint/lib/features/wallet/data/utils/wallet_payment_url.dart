/// True when [value] is an HTTP(S) URL suitable for WebView / external browser.
bool isWalletPaymentWebUrl(String? value) {
  final url = value?.trim();
  if (url == null || url.isEmpty) return false;
  return url.startsWith('http://') || url.startsWith('https://');
}

/// Picks the first HTTP(S) payment URL from API fields.
String? pickWalletPaymentUrl(Map<String, dynamic> json) {
  for (final key in [
    'paymentUrl',
    'paymentGatewayUrl',
    'checkoutUrl',
  ]) {
    final value = json[key]?.toString().trim();
    if (isWalletPaymentWebUrl(value)) return value;
  }
  final ref = json['gatewayPaymentReference']?.toString().trim();
  if (isWalletPaymentWebUrl(ref)) return ref;
  return null;
}
