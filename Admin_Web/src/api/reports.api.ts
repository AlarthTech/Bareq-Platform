import { apiClient } from '../core/api/client';
import type { PagedResult } from '../types/api.types';
import type { Report, ReportStatusUpdate } from '../types/report.types';

export const reportsApi = {
  list: (page = 1, pageSize: number = 20) =>
    apiClient.get<PagedResult<Report>>('/Reports/GetReports', { page, pageSize }),

  getById: (id: number) => apiClient.get<Report>(`/Reports/GetReportById/${id}`),

  updateStatus: (id: number, data: ReportStatusUpdate) =>
    apiClient.patch<Report>(`/Reports/UpdateReportStatus/${id}`, data),

  remove: (id: number) => apiClient.delete<void>(`/Reports/DeleteReport/${id}`),

  countPending: async (): Promise<number> => {
    const result = await reportsApi.list(1, 50);
    return result.items.filter((r) => r.status === 0).length;
  },
};
