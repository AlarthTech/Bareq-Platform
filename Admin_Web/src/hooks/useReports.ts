import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { reportsApi } from '../api/reports.api';
import type { ReportStatusUpdate } from '../types/report.types';

export function useReports(page: number, pageSize: number = 20) {
  return useQuery({
    queryKey: ['reports', page, pageSize],
    queryFn: () => reportsApi.list(page, pageSize),
  });
}

export function useReport(id: number) {
  return useQuery({
    queryKey: ['reports', id],
    queryFn: () => reportsApi.getById(id),
    enabled: id > 0,
  });
}

export function usePendingReportsCount() {
  return useQuery({
    queryKey: ['reports', 'pending-count'],
    queryFn: reportsApi.countPending,
  });
}

export function useUpdateReportStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: { id: number } & ReportStatusUpdate) =>
      reportsApi.updateStatus(id, data),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['reports'] });
      qc.invalidateQueries({ queryKey: ['reports', id] });
    },
  });
}

export function useDeleteReport() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => reportsApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['reports'] }),
  });
}
