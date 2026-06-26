import type { QueryClient } from '@tanstack/react-query';
import type { Booking } from '../../../types/api.types';
import type { PagedResult } from '../../../types/api.types';

function patchBooking(booking: Booking, status: number, rejectionReason?: string): Booking {
  return {
    ...booking,
    status,
    ...(rejectionReason !== undefined ? { rejectionReason } : {}),
  };
}

function patchQueryData(data: unknown, bookingId: number, status: number, rejectionReason?: string): unknown {
  if (!data) return data;

  if (Array.isArray(data)) {
    return (data as Booking[]).map((b) =>
      b.id === bookingId ? patchBooking(b, status, rejectionReason) : b
    );
  }

  if (typeof data === 'object' && data !== null && 'items' in data) {
    const paged = data as PagedResult<Booking>;
    return {
      ...paged,
      items: paged.items.map((b) =>
        b.id === bookingId ? patchBooking(b, status, rejectionReason) : b
      ),
    };
  }

  if (typeof data === 'object' && data !== null && 'id' in data) {
    const booking = data as Booking;
    if (booking.id === bookingId) {
      return patchBooking(booking, status, rejectionReason);
    }
  }

  return data;
}

/** Instantly update booking status across all cached list/detail queries. */
export function patchBookingStatusInCache(
  qc: QueryClient,
  bookingId: number,
  status: number,
  rejectionReason?: string
) {
  qc.setQueriesData({ queryKey: ['bookings'] }, (old) =>
    patchQueryData(old, bookingId, status, rejectionReason)
  );
}
