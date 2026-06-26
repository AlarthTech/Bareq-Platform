using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Models.Customers;

namespace CleaningHouse_API.Data;

public static class BookingQueries
{
    public static IQueryable<BookingDTO> ProjectToDto(this IQueryable<Booking> query) =>
        query.Select(b => new BookingDTO
        {
            Id = b.Id,
            UserId = b.UserId,
            UserName = b.AppUser != null ? b.AppUser.FullName : null,
            CompanyId = b.CompanyId,
            CompanyName = b.Company != null ? b.Company.Name : null,
            WorkerId = b.WorkerId,
            WorkerName = b.Worker != null ? b.Worker.FullName : null,
            WorkTypeId = b.WorkTypeId,
            WorkTypeName = b.WorkType != null ? b.WorkType.Name : null,
            BookingDate = b.BookingDate,
            StartDate = b.StartDate,
            EndDate = b.EndDate,
            Address = b.Address,
            UserLocationId = b.UserLocationId,
            LocationName = b.UserLocation != null ? b.UserLocation.LocationName : null,
            Lat = b.UserLocation != null ? b.UserLocation.Lat : null,
            Lng = b.UserLocation != null ? b.UserLocation.Lng : null,
            Status = b.Status,
            RejectionReason = b.RejectionReason,
            ServicePrice = b.ServicePrice,
            PlatformFeeAmount = b.PlatformFeeAmount,
            TotalPrice = b.TotalPrice,
            IsMonthlyPricing = b.IsMonthlyPricing,
            IsWorkerArrivalConfirmed = b.IsWorkerArrivalConfirmed,
            WorkerArrivalConfirmedAt = b.WorkerArrivalConfirmedAt,
            WalletAmountReserved = b.WalletAmountReserved,
            WalletAmountCaptured = b.WalletAmountCaptured,
            WalletCapturedAt = b.WalletCapturedAt,
            CreatedAt = b.CreatedAt
        });
}
