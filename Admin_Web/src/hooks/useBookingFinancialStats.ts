import { useQuery } from '@tanstack/react-query';
import { bookingsApi } from '../api/bookings.api';
import { COMPANY_COMMISSION_PER_BOOKING_LYD } from '../core/constants';
import { calculateCompanyCommission, isLegacyBookingPricing } from '../core/utils';
import { BookingStatus } from '../types/booking-status';

function isCompletedPricedBooking(booking: { status: number; servicePrice: number; platformFeeAmount: number; totalPrice: number }) {
  return booking.status === BookingStatus.Completed && !isLegacyBookingPricing(booking);
}

export function useBookingFinancialStats() {
  return useQuery({
    queryKey: ['bookings', 'financial-stats'],
    queryFn: bookingsApi.fetchAll,
    select: (bookings) => {
      const completedPriced = bookings.filter(isCompletedPricedBooking);
      const totalPlatformFees = completedPriced.reduce((s, b) => s + b.platformFeeAmount, 0);
      const totalCompanyCommission = calculateCompanyCommission(completedPriced.length);
      const totalCommissions = totalPlatformFees + totalCompanyCommission;

      return {
        totalPlatformFees,
        totalCompanyCommission,
        totalCommissions,
        totalRevenue: completedPriced.reduce((s, b) => s + b.totalPrice, 0),
        serviceRevenue: completedPriced.reduce((s, b) => s + b.servicePrice, 0),
        companyNetFromService: completedPriced.reduce(
          (s, b) => s + Math.max(0, b.servicePrice - COMPANY_COMMISSION_PER_BOOKING_LYD),
          0
        ),
        completedPricedBookingsCount: completedPriced.length,
        completedBookingsCount: bookings.filter((b) => b.status === BookingStatus.Completed).length,
        totalBookingsCount: bookings.length,
      };
    },
    staleTime: 5 * 60_000,
  });
}
