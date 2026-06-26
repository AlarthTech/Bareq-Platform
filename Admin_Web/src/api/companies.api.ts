import { apiClient } from '../core/api/client';
import type { Company, PaginationParams, PagedResult, ToggleResponse } from '../types/api.types';

function toggleMessage(
  data: ToggleResponse | undefined,
  fallback: string
): ToggleResponse {
  if (data?.message?.trim()) return data;
  return { message: fallback };
}

async function patchToggle(
  url: string,
  fallbackMessage: string
): Promise<ToggleResponse> {
  const data = await apiClient.patch<ToggleResponse | undefined>(url);
  return toggleMessage(data, fallbackMessage);
}

export const companiesApi = {
  getAll: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Company>>('/Companies/GetAllCompanies', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    }),

  getActive: (params: PaginationParams = {}) =>
    apiClient.get<PagedResult<Company>>('/Companies/GetActiveCompanies', {
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 50,
    }),

  getActiveIds: async (): Promise<Set<number>> => {
    const pageSize = 50;
    const ids = new Set<number>();
    let page = 1;
    let hasNextPage = true;

    while (hasNextPage) {
      const result = await companiesApi.getActive({ page, pageSize });
      for (const company of result.items) {
        ids.add(company.id);
      }
      hasNextPage = result.hasNextPage;
      page += 1;
    }

    return ids;
  },

  fetchAll: async (): Promise<Company[]> => {
    const pageSize = 50;
    const all: Company[] = [];
    let page = 1;
    let hasNextPage = true;

    while (hasNextPage) {
      const result = await companiesApi.getAll({ page, pageSize });
      all.push(...result.items);
      hasNextPage = result.hasNextPage;
      page += 1;
    }

    return all;
  },

  toggleVerified: (id: number) =>
    patchToggle(
      `/Companies/UpdateCompanyisVerified/${id}`,
      'تم تحديث حالة التوثيق'
    ),

  toggleActive: (id: number) =>
    patchToggle(
      `/Companies/UpdateCompanyIsActive/${id}`,
      'تم تحديث حالة التفعيل'
    ),

  approve: async (id: number): Promise<ToggleResponse> => {
    const activeIds = await companiesApi.getActiveIds();
    await patchToggle(
      `/Companies/UpdateCompanyisVerified/${id}`,
      'تم توثيق الشركة'
    );
    if (!activeIds.has(id)) {
      await patchToggle(
        `/Companies/UpdateCompanyIsActive/${id}`,
        'تم تفعيل الشركة'
      );
    }
    return { message: 'تم اعتماد الشركة وتفعيلها بنجاح' };
  },

  update: (
    id: number,
    data: {
      name: string;
      address?: string;
      commercialRegNo?: string;
      email: string;
      cityId: number;
      experienceYears: number;
      description?: string;
    }
  ) => apiClient.patch(`/Companies/UpdateCompany/${id}`, data),

  create: (data: Record<string, unknown>) =>
    apiClient.post('/Companies/CreateCompany', data),

  delete: (id: number) => apiClient.delete(`/Companies/DeleteCompany/${id}`),

  uploadCommercialRegister: (id: number, file: File) =>
    apiClient.upload(`/Companies/UploadCommercialRegister/${id}`, file),

  updateCommercialRegister: (id: number, file: File) =>
    apiClient.upload(`/Companies/UpdateCommercialRegister/${id}`, file),
};
