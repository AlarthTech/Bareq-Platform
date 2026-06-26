import { apiClient } from '../core/api/client';
import type { PaginationParams, PagedResult, ToggleResponse, Worker } from '../types/api.types';

export const workersApi = {
  getAll: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Worker>>('/Workers/GetWorkers', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  getByCompany: (companyId: number, params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Worker>>(`/Workers/Company/${companyId}`, {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  create: (data: Record<string, unknown>) => apiClient.post('/Workers/CreateWorker', data),

  update: (id: number, data: Record<string, unknown>) =>
    apiClient.patch(`/Workers/UpdateWorker/${id}`, data),

  toggleActive: (id: number) =>
    apiClient.patch<ToggleResponse>(`/Workers/UpdateWorkerIsActive/${id}`),

  toggleAvailable: (id: number) =>
    apiClient.patch<ToggleResponse>(`/Workers/UpdateWorkerIsAvailable/${id}`),

  uploadHealthCertificate: (id: number, file: File) =>
    apiClient.upload(`/Workers/UploadHealthCertificate/${id}`, file),

  updateHealthCertificate: (id: number, file: File) =>
    apiClient.upload(`/Workers/UpdateHealthCertificate/${id}`, file, 'file'),

  delete: (id: number) => apiClient.delete(`/Workers/DeleteWorker/${id}`),
};
