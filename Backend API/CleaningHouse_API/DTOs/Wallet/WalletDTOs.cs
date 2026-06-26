using System.ComponentModel.DataAnnotations;

namespace CleaningHouse_API.DTOs.Wallet;

public class WalletSummaryDTO
{
    public int WalletId { get; set; }
    public int CustomerId { get; set; }
    public decimal Balance { get; set; }
    public decimal ReservedBalance { get; set; }
    public decimal AvailableBalance { get; set; }
    public string Currency { get; set; } = "LYD";
    public bool IsActive { get; set; }
    public bool IsWalletPaymentEnabled { get; set; }
    public decimal WalletPaymentFeePercentage { get; set; }
}

public class WalletTransactionDTO
{
    public int Id { get; set; }
    public int WalletId { get; set; }
    public int CustomerId { get; set; }
    public int? BookingId { get; set; }
    public decimal Amount { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Direction { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Notes { get; set; }
    public int? CreatedByAdminId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class CreateWalletTopUpDTO
{
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal RequestedAmount { get; set; }

    [Required]
    [MaxLength(50)]
    public string PaymentMethod { get; set; } = string.Empty;

    [MaxLength(100)]
    public string? TransferReferenceNumber { get; set; }

    [MaxLength(500)]
    public string? TransferReceiptImageUrl { get; set; }

    [MaxLength(500)]
    public string? Notes { get; set; }
}

public class WalletTopUpDTO
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public decimal RequestedAmount { get; set; }
    public decimal? ApprovedAmount { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? TransferReferenceNumber { get; set; }
    public string? TransferReceiptImageUrl { get; set; }
    public string? GatewayPaymentReference { get; set; }
    public string? Notes { get; set; }
    public string? AdminNotes { get; set; }
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class ConfirmBankCardTopUpDTO
{
    [Required]
    [MaxLength(100)]
    public string PaymentReference { get; set; } = string.Empty;
}

public class FailBankCardTopUpDTO
{
    [MaxLength(500)]
    public string? Reason { get; set; }
}

public class ApproveBankTransferTopUpDTO
{
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal ApprovedAmount { get; set; }

    [MaxLength(500)]
    public string? AdminNotes { get; set; }
}

public class RejectBankTransferTopUpDTO
{
    [Required]
    [MaxLength(500)]
    public string Reason { get; set; } = string.Empty;
}

public class WalletPaymentSettingsDTO
{
    public bool IsWalletPaymentEnabled { get; set; }
    public decimal WalletPaymentFeePercentage { get; set; }
    public DateTime UpdatedAt { get; set; }
    public int? UpdatedByAdminId { get; set; }
}

public class UpdateWalletPaymentSettingsDTO
{
    public bool IsWalletPaymentEnabled { get; set; }

    [Range(0, 100)]
    public decimal WalletPaymentFeePercentage { get; set; }
}

public class WalletBookingPaymentQuoteDTO
{
    public decimal BookingTotal { get; set; }
    public decimal WalletFee { get; set; }
    public decimal RequiredAmount { get; set; }
    public decimal WalletBalance { get; set; }
    public bool IsWalletPaymentEnabled { get; set; }
    public bool HasSufficientBalance { get; set; }
}

public class WalletBookingPaymentResultDTO
{
    public string Message { get; set; } = string.Empty;
    public int BookingId { get; set; }
    public decimal BookingTotal { get; set; }
    public decimal WalletFee { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal RemainingWalletBalance { get; set; }
    public bool WalletAmountReserved { get; set; }
    public bool WalletAmountCaptured { get; set; }
}

public class BankCardTopUpRequestDTO
{
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Amount { get; set; }
}

public class BankCardTopUpStartResponseDTO
{
    public int TopUpId { get; set; }
    public string PaymentUrl { get; set; } = string.Empty;
    public string GatewayPaymentReference { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class WalletTopUpCallbackRequestDTO
{
    [Required]
    public int TopUpId { get; set; }

    [Required]
    [MaxLength(100)]
    public string PaymentReference { get; set; } = string.Empty;

    [Required]
    public bool Success { get; set; }

    [MaxLength(500)]
    public string? FailureReason { get; set; }
}

public class WalletTopUpCallbackResponseDTO
{
    public bool Credited { get; set; }
    public int TopUpId { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal? NewWalletBalance { get; set; }
    public string Message { get; set; } = string.Empty;
}

public class InsufficientWalletBalanceDTO
{
    public string Message { get; set; } = "Insufficient wallet balance. Please charge your wallet to continue.";
    public decimal WalletBalance { get; set; }
    public decimal RequiredAmount { get; set; }
}

public class BankTransferAccountDTO
{
    public int Id { get; set; }
    public string BankName { get; set; } = string.Empty;
    public string AccountHolderName { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string? Iban { get; set; }
    public string? BranchName { get; set; }
    public string? Instructions { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateBankTransferAccountDTO
{
    [Required]
    [MaxLength(200)]
    public string BankName { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string AccountHolderName { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string AccountNumber { get; set; } = string.Empty;

    [MaxLength(50)]
    public string? Iban { get; set; }

    [MaxLength(200)]
    public string? BranchName { get; set; }

    [MaxLength(1000)]
    public string? Instructions { get; set; }
}

public class UpdateBankTransferAccountDTO : CreateBankTransferAccountDTO
{
}

public class AdminManualWalletCreditDTO
{
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Amount { get; set; }

    [MaxLength(500)]
    public string? Notes { get; set; }
}

public class AdminBulkWalletCreditDTO
{
    [Required]
    [MinLength(1)]
    public List<int> CustomerIds { get; set; } = [];

    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Amount { get; set; }

    [MaxLength(500)]
    public string? Notes { get; set; }
}

public class BulkWalletCreditResultDTO
{
    public int SuccessCount { get; set; }
    public IReadOnlyList<int> CreditedCustomerIds { get; set; } = [];
    public string Message { get; set; } = string.Empty;
}
