using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.DTOs.Wallet;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Services.Wallet;

public interface IBookingWalletService
{
    Task<WalletBookingPaymentResultDTO> ReserveBookingWalletPaymentAsync(
        int customerId,
        int bookingId,
        decimal bookingTotal,
        CancellationToken cancellationToken = default);

    Task<BookingDTO> ConfirmWorkerArrivalAsync(
        int customerId,
        int bookingId,
        CancellationToken cancellationToken = default);

    /// <summary>Called after booking status is saved — handles capture, release, or refund.</summary>
    Task ApplyBookingStatusWalletEffectsAsync(
        Booking booking,
        int previousStatus,
        int newStatus,
        CancellationToken cancellationToken = default);
}
