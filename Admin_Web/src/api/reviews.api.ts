import { apiClient } from '../core/api/client';
import type { PaginationParams, PagedResult, Review } from '../types/api.types';

export const reviewsApi = {
  getAll: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Review>>('/Reviews/GetReviews', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  getByWorker: (workerId: number, params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Review>>(`/Reviews/Worker/${workerId}`, {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  getByBooking: (bookingId: number, params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Review>>(`/Reviews/Booking/${bookingId}`, {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  update: (id: number, data: { rating: number; comment?: string }) =>
    apiClient.patch(`/Reviews/UpdateReview/${id}`, data),

  delete: (id: number) => apiClient.delete(`/Reviews/DeleteReview/${id}`),
};
