import { apiClient } from '../core/api/client';
import type { PagedResult } from '../types/api.types';
import type {
  BookingReport,
  BookingReportFilters,
  UpdateBookingReportStatusPayload,
} from '../types/booking-report';
import { BookingReportStatus } from '../types/booking-report';

function buildListParams(filters: BookingReportFilters): Record<string, unknown> {
  return {
    page: filters.page ?? 1,
    pageSize: filters.pageSize ?? 20,
    ...(filters.status != null && { status: filters.status }),
    ...(filters.bookingId != null && { bookingId: filters.bookingId }),
    ...(filters.customerId != null && { customerId: filters.customerId }),
    ...(filters.companyId != null && { companyId: filters.companyId }),
    ...(filters.workerId != null && { workerId: filters.workerId }),
    ...(filters.fromDate && { fromDate: filters.fromDate }),
    ...(filters.toDate && { toDate: filters.toDate }),
  };
}

export const bookingReportsApi = {
  list: (filters: BookingReportFilters = {}) =>
    apiClient.get<PagedResult<BookingReport>>('/BookingReports', buildListParams(filters)),

  getById: (id: number) => apiClient.get<BookingReport>(`/BookingReports/${id}`),

  updateStatus: (id: number, data: UpdateBookingReportStatusPayload) =>
    apiClient.patch<BookingReport>(`/BookingReports/${id}/Status`, data),

  countOpen: async (): Promise<number> => {
    const result = await bookingReportsApi.list({
      status: BookingReportStatus.Open,
      page: 1,
      pageSize: 1,
    });
    return result.totalCount;
  },
};
