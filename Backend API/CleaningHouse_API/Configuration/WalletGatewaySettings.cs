namespace CleaningHouse_API.Configuration;

public class WalletGatewaySettings
{
    public const string SectionName = "WalletGateway";

    /// <summary>URL opened in app WebView to complete card payment (gateway hosted page).</summary>
    public string PaymentPageBaseUrl { get; set; } = "https://payment-gateway-url.com/pay";

    /// <summary>Shared secret for POST /api/v1/payments/wallet-top-up/callback (header X-Wallet-Callback-Secret).</summary>
    public string CallbackSecret { get; set; } = string.Empty;

    public bool EnableTestInstantBankCardTopUp { get; set; }

    public string TestInstantTopUpSecret { get; set; } = string.Empty;
}
