import { apiClient } from '../core/api/client';
import { PAGINATION } from '../core/constants';
import type { AppUser, PaginationParams, PagedResult } from '../types/api.types';

export const usersApi = {
  getAll: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<AppUser>>('/AppUsers/GetAllAppUsers', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? PAGINATION.DEFAULT_PAGE_SIZE,
    }),

  /** Fetches every page from the API and returns all active users. */
  fetchAll: async (): Promise<AppUser[]> => {
    const pageSize = PAGINATION.MAX_PAGE_SIZE;
    const all: AppUser[] = [];
    let page = 1;
    let hasNextPage = true;

    while (hasNextPage) {
      const result = await usersApi.getAll({ page, pageSize });
      all.push(...result.items);
      hasNextPage = result.hasNextPage;
      page += 1;
    }

    return all;
  },

  getById: (id: number) => apiClient.get<AppUser>(`/AppUsers/GetAppUserById/${id}`),

  update: (
    id: number,
    data: { fullName: string; phone: string; email: string; password?: string }
  ) => apiClient.patch(`/AppUsers/UpdateAppUser/${id}`, data),

  delete: (id: number) => apiClient.delete(`/AppUsers/DeleteAppUser/${id}`),

  createAdmin: (data: {
    fullName: string;
    phone: string;
    email: string;
    password: string;
    cityId?: number;
  }) => apiClient.post('/AppUsers/CreateNewAdmin', data),

  createCompanyOwner: (data: Record<string, unknown>) =>
    apiClient.post('/AppUsers/CreateNewCompanyOwner', data),

  createCustomer: (data: Record<string, unknown>) =>
    apiClient.post('/AppUsers/CreateNewCustomer', data),
};
