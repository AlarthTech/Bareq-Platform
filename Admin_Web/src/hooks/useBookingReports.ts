import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { bookingReportsApi } from '../api/booking-reports.api';
import type {
  BookingReportFilters,
  UpdateBookingReportStatusPayload,
} from '../types/booking-report';

export function useBookingReports(filters: BookingReportFilters) {
  return useQuery({
    queryKey: ['booking-reports', filters],
    queryFn: () => bookingReportsApi.list(filters),
  });
}

export function useBookingReport(id: number) {
  return useQuery({
    queryKey: ['booking-reports', id],
    queryFn: () => bookingReportsApi.getById(id),
    enabled: id > 0,
  });
}

export function useOpenBookingReportsCount() {
  return useQuery({
    queryKey: ['booking-reports', 'open-count'],
    queryFn: bookingReportsApi.countOpen,
    staleTime: 30_000,
  });
}

export function useUpdateBookingReportStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: { id: number } & UpdateBookingReportStatusPayload) =>
      bookingReportsApi.updateStatus(id, data),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['booking-reports'] });
      qc.invalidateQueries({ queryKey: ['booking-reports', id] });
      qc.invalidateQueries({ queryKey: ['booking-reports', 'open-count'] });
    },
  });
}
