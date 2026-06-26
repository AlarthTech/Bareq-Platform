import { apiClient } from '../core/api/client';
import type { Favorite, PaginationParams, PagedResult } from '../types/api.types';

export const favoritesApi = {
  getAll: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Favorite>>('/Favorites/GetFavorites', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  delete: (id: number) => apiClient.delete(`/Favorites/DeleteFavorite/${id}`),

  deleteByUserAndWorker: (userId: number, workerId: number) =>
    apiClient.delete(`/Favorites/DeleteFavoriteByUserAndWorker/${userId}/${workerId}`),
};
