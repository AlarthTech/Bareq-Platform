import { useQuery } from '@tanstack/react-query';
import { bookingsApi } from '../api/bookings.api';

export function useBooking(id: number) {
  return useQuery({
    queryKey: ['bookings', id],
    queryFn: () => bookingsApi.getById(id),
    enabled: Number.isFinite(id) && id > 0,
  });
}
