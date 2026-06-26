import { apiClient } from '../core/api/client';
import type { PaginationParams, PagedResult, WorkType } from '../types/api.types';

export const workTypesApi = {
  getAll: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<WorkType>>('/WorkTypes/GetAllWorkTypes', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  getByCompany: (companyId: number, params: PaginationParams = {}) =>
    apiClient.get<PagedResult<WorkType>>(`/WorkTypes/GetWorkTypesByCompany/${companyId}`, {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  create: (data: Record<string, unknown>) => apiClient.post('/WorkTypes/CreateWorkType', data),

  update: (id: number, data: Record<string, unknown>) =>
    apiClient.patch(`/WorkTypes/UpdateWorkType/${id}`, data),

  delete: (id: number) => apiClient.delete(`/WorkTypes/DeleteWorkType/${id}`),

  assignToWorker: (workerId: number, workTypeId: number) =>
    apiClient.post('/WorkTypes/AssignWorkTypeToWorker', { workerId, workTypeId }),

  getWorkerWorkTypes: (workerId: number) =>
    apiClient.get<WorkType[]>(`/WorkTypes/GetWorkerWorkTypes/${workerId}`),

  removeFromWorker: (workerId: number, workTypeId: number) =>
    apiClient.delete(
      `/WorkTypes/RemoveWorkTypeFromWorker?workerId=${workerId}&workTypeId=${workTypeId}`
    ),
};
