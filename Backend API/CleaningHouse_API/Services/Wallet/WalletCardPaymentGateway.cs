using CleaningHouse_API.Configuration;
using Microsoft.Extensions.Options;

namespace CleaningHouse_API.Services.Wallet;

public class WalletCardPaymentGateway : IWalletCardPaymentGateway
{
    private readonly WalletGatewaySettings _settings;

    public WalletCardPaymentGateway(IOptions<WalletGatewaySettings> settings)
    {
        _settings = settings.Value;
    }

    public string BuildPaymentUrl(int topUpId, string gatewayPaymentReference, decimal amount)
    {
        var baseUrl = _settings.PaymentPageBaseUrl.TrimEnd('/');
        var query = $"topUpId={topUpId}&reference={Uri.EscapeDataString(gatewayPaymentReference)}&amount={amount}";
        return $"{baseUrl}?{query}";
    }
}
