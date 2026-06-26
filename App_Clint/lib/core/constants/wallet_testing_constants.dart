/// Server test instant top-up (`POST /api/v1/wallet/test/bank-card-charge`).
abstract final class WalletTestingConstants {
  WalletTestingConstants._();

  /// Optional — set via `--dart-define=WALLET_TEST_SECRET=...` when the API requires it.
  static const String testInstantTopUpSecret = String.fromEnvironment(
    'WALLET_TEST_SECRET',
    defaultValue: '',
  );
}
