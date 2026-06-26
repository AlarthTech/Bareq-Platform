import { apiClient } from '../core/api/client';
import type { PagedResult } from '../types/api.types';
import type {
  CreateReferenceItem,
  ReferenceItem,
  UpdateReferenceItem,
} from '../types/reference.types';
import type { CleaningService, PaginationParams, UserType } from '../types/api.types';

export const citiesApi = {
  list: (page = 1, pageSize = 20) =>
    apiClient.get<PagedResult<ReferenceItem>>('/Cities/GetAllCities', { page, pageSize }),

  getById: (id: number) => apiClient.get<ReferenceItem>(`/Cities/GetCityById/${id}`),

  create: (data: CreateReferenceItem) =>
    apiClient.post<ReferenceItem>('/Cities/CreateCity', data),

  update: (id: number, data: UpdateReferenceItem) =>
    apiClient.patch<void>(`/Cities/UpdateCity/${id}`, data),

  remove: (id: number) => apiClient.delete<void>(`/Cities/DeleteCity/${id}`),
};

export const nationalitiesApi = {
  list: () => apiClient.get<ReferenceItem[]>('/Nationalities/GetNationalities'),

  getById: (id: number) =>
    apiClient.get<ReferenceItem>(`/Nationalities/GetNationalityById/${id}`),

  create: (data: CreateReferenceItem) =>
    apiClient.post<ReferenceItem>('/Nationalities/CreateNationality', data),

  update: (id: number, data: UpdateReferenceItem) =>
    apiClient.patch<void>(`/Nationalities/UpdateNationality/${id}`, data),

  deactivate: (id: number) =>
    apiClient.patch<void>(`/Nationalities/UpdateNationality/${id}`, { isActive: false }),
};

export const languagesApi = {
  list: () => apiClient.get<ReferenceItem[]>('/Languages/GetAllLanguages'),

  getById: (id: number) =>
    apiClient.get<ReferenceItem>(`/Languages/GetLanguageById/${id}`),

  create: (data: CreateReferenceItem) =>
    apiClient.post<ReferenceItem>('/Languages/CreateLanguage', data),

  update: (id: number, data: UpdateReferenceItem) =>
    apiClient.patch<void>(`/Languages/UpdateLanguage/${id}`, data),

  deactivate: (id: number) =>
    apiClient.patch<void>(`/Languages/UpdateLanguage/${id}`, { isActive: false }),
};

/** Cleaning services & user types — unchanged */
export const referenceApi = {
  getCleaningServices: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<CleaningService>>('/CleaningServices/GetCleaningServices', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  createCleaningService: (data: { name: string; description?: string }) =>
    apiClient.post('/CleaningServices/CreateCleaningService', data),

  updateCleaningService: (id: number, data: { name: string; description?: string }) =>
    apiClient.patch(`/CleaningServices/UpdateCleaningService/${id}`, data),

  deleteCleaningService: (id: number) =>
    apiClient.delete(`/CleaningServices/DeleteCleaningService/${id}`),

  getUserTypes: () => apiClient.get<UserType[]>('/UserTypes'),
};
