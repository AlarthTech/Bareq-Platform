using CleaningHouse_API.Data;
using CleaningHouse_API.DTOs.Customers;
using CleaningHouse_API.Services.Commission;
using Microsoft.EntityFrameworkCore;

namespace CleaningHouse_API.Services.Bookings;

public class BookingPricingService : IBookingPricingService
{
    private readonly ApplicationDbContext _context;
    private readonly IPlatformFeeService _platformFeeService;

    public BookingPricingService(ApplicationDbContext context, IPlatformFeeService platformFeeService)
    {
        _context = context;
        _platformFeeService = platformFeeService;
    }

    public async Task<BookingPricingResult> CalculateAsync(
        BookingPricingRequestDTO request,
        CancellationToken cancellationToken = default)
    {
        var servicePrice = await ResolveServicePriceAsync(request, cancellationToken);
        var platformFee = await _platformFeeService.GetActivePlatformFeeAmountAsync(cancellationToken);

        return new BookingPricingResult
        {
            ServicePrice = servicePrice,
            PlatformFeeAmount = platformFee,
            TotalPrice = servicePrice + platformFee
        };
    }

    private async Task<decimal> ResolveServicePriceAsync(
        BookingPricingRequestDTO request,
        CancellationToken cancellationToken)
    {
        var company = await _context.Companies.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == request.CompanyId && c.IsActive && c.IsVerified, cancellationToken);
        if (company == null)
            throw new BookingPricingValidationException("الشركة غير موجودة أو غير نشطة");

        var worker = await _context.Workers.AsNoTracking()
            .FirstOrDefaultAsync(w => w.Id == request.WorkerId && w.IsActive, cancellationToken);
        if (worker == null)
            throw new BookingPricingValidationException("العاملة غير موجودة أو غير نشطة");

        if (worker.CompanyId != request.CompanyId)
            throw new BookingPricingValidationException("العاملة لا تنتمي إلى هذه الشركة");

        if (!worker.IsAvailable)
            throw new BookingPricingValidationException("العاملة غير متاحة للحجز");

        var workType = await _context.WorkTypes.AsNoTracking()
            .FirstOrDefaultAsync(wt =>
                wt.Id == request.WorkTypeId
                && wt.CompanyId == request.CompanyId
                && wt.IsActive,
                cancellationToken);
        if (workType == null)
            throw new BookingPricingValidationException("نوع العمل غير موجود أو لا يتبع هذه الشركة");

        var workerHasWorkType = await _context.WorkerWorkTypes.AsNoTracking()
            .AnyAsync(wwt => wwt.WorkerId == request.WorkerId && wwt.WorkTypeId == request.WorkTypeId, cancellationToken);
        if (!workerHasWorkType)
            throw new BookingPricingValidationException("العاملة غير مرتبطة بنوع العمل المحدد");

        if (request.IsMonthly)
        {
            if (!workType.MonthlyPrice.HasValue)
                throw new BookingPricingValidationException("نوع العمل المحدد لا يدعم التسعير الشهري");

            return workType.MonthlyPrice.Value;
        }

        return workType.Price;
    }
}
