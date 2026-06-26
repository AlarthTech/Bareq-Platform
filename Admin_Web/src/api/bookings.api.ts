import { apiClient } from '../core/api/client';
import type { Booking, PaginationParams, PagedResult } from '../types/api.types';

export const bookingsApi = {
  getAll: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Booking>>('/Bookings/GetBookings', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  fetchAll: async (): Promise<Booking[]> => {
    const pageSize = 50;
    const all: Booking[] = [];
    let page = 1;
    let hasNextPage = true;

    while (hasNextPage) {
      const result = await bookingsApi.getAll({ page, pageSize });
      all.push(...result.items);
      hasNextPage = result.hasNextPage;
      page += 1;
    }

    return all;
  },

  getById: (id: number) => apiClient.get<Booking>(`/Bookings/GetBookingById/${id}`),

  updateStatus: (id: number, data: { status: number; rejectionReason?: string }) =>
    apiClient.patch(`/Bookings/UpdateStatusBooking/${id}`, data),

  update: (id: number, data: Record<string, unknown>) =>
    apiClient.patch(`/Bookings/UpdateBooking/${id}`, data),

  delete: (id: number) => apiClient.delete(`/Bookings/DeleteBooking/${id}`),
};
