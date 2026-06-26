namespace CleaningHouse_API.Services.Wallet;

public interface IWalletCardPaymentGateway
{
    string BuildPaymentUrl(int topUpId, string gatewayPaymentReference, decimal amount);
}
