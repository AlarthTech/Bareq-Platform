namespace CleaningHouse_API.Services.Wallet;

public static class WalletFeeCalculator
{
    public static (decimal WalletFee, decimal FinalAmount) Calculate(decimal bookingTotal, decimal feePercentage)
    {
        if (bookingTotal < 0)
            throw new ArgumentOutOfRangeException(nameof(bookingTotal));

        if (feePercentage is < 0 or > 100)
            throw new ArgumentOutOfRangeException(nameof(feePercentage));

        var walletFee = Math.Round(bookingTotal * feePercentage / 100m, 2, MidpointRounding.AwayFromZero);
        var finalAmount = bookingTotal + walletFee;
        return (walletFee, finalAmount);
    }
}
