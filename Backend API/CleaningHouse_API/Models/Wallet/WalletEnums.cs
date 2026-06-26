namespace CleaningHouse_API.Models.Wallet;

public static class WalletPaymentMethods
{
    public const string BankCard = "BankCard";
    public const string BankTransfer = "BankTransfer";
    public const string Wallet = "Wallet";
}

public static class WalletTransactionTypes
{
    public const string BankCardTopUp = "BankCardTopUp";
    public const string BankTransferTopUp = "BankTransferTopUp";
    public const string WalletPayment = "WalletPayment";
    public const string WalletReserve = "WalletReserve";
    public const string WalletCapture = "WalletCapture";
    public const string WalletRelease = "WalletRelease";
    public const string WalletRefund = "WalletRefund";
    public const string ManualCredit = "ManualCredit";
    public const string ManualDebit = "ManualDebit";
}

public static class WalletTransactionDirections
{
    public const string Credit = "Credit";
    public const string Debit = "Debit";
}

public static class WalletTransactionStatuses
{
    public const string Pending = "Pending";
    public const string Completed = "Completed";
    public const string Rejected = "Rejected";
    public const string Failed = "Failed";
}

public static class WalletTopUpStatuses
{
    public const string Pending = "Pending";
    public const string Completed = "Completed";
    public const string Approved = "Approved";
    public const string Rejected = "Rejected";
    public const string Failed = "Failed";
}

public static class WalletRefundStatuses
{
    public const int None = 0;
    public const int Refunded = 1;
}

public static class PaymentStatuses
{
    public const int Pending = 0;
    public const int Paid = 1;
    public const int Failed = 2;
    public const int Released = 3;
}
