import { apiClient } from '../../core/api/client';
import type { PaginatedResponse } from '../../core/types';
import type { Company, CompanyApiResponse } from './types';
import type { AppUserApiResponse } from '../users/types';

// Helper function to map API response to UI format
const mapCompanyResponse = (
  apiCompany: CompanyApiResponse,
  ownerMap?: Map<string, AppUserApiResponse>
): Company => {
  const companyName = apiCompany.name || apiCompany.fullName || 'Unknown Company';
  const companyNameAr = apiCompany.nameAr || companyName;
  const companyEmail = apiCompany.email || '';
  
  // Map isVerified to status:
  // isVerified: true → active
  // isVerified: false → pending
  let status: 'active' | 'pending' | 'inactive' = 'pending';
  if (apiCompany.isVerified === true) {
    status = 'active';
  } else if (apiCompany.isVerified === false) {
    status = 'pending';
  } else if (apiCompany.isActive === false) {
    status = 'inactive';
  }
  
  // Find matching owner by email (userTypeName === "Company")
  let ownerId: string | undefined;
  let ownerName = apiCompany.fullName || companyName;
  
  if (ownerMap && companyEmail) {
    const owner = ownerMap.get(companyEmail.toLowerCase());
    if (owner && owner.userTypeName === 'Company') {
      ownerId = owner.id.toString();
      ownerName = owner.fullName;
    }
  }
  
  return {
    id: apiCompany.id.toString(),
    name: companyName,
    nameAr: companyNameAr,
    ownerName,
    ownerEmail: companyEmail,
    ownerId,
    phone: apiCompany.phone || '',
    email: companyEmail,
    city: apiCompany.cityName || apiCompany.city || 'N/A',
    status,
    createdAt: apiCompany.createdAt || new Date().toISOString(),
  };
};

export const companiesApi = {
  getCompanies: async (params?: {
    page?: number;
    pageSize?: number;
    search?: string;
    status?: string;
  }): Promise<PaginatedResponse<Company>> => {
    try {
      // Fetch companies and users in parallel
      const [companiesResponse, usersResponse] = await Promise.all([
        apiClient.get<CompanyApiResponse[]>('/Companies/GetAllCompanies'),
        apiClient.get<AppUserApiResponse[]>('/AppUsers/GetAllAppUsers'),
      ]);

      // Create a map of owners (userTypeName === "Company") by email
      const ownerMap = new Map<string, AppUserApiResponse>();
      usersResponse
        .filter((user) => user.userTypeName === 'Company')
        .forEach((user) => {
          if (user.email) {
            ownerMap.set(user.email.toLowerCase(), user);
          }
        });

      // Map API responses to UI format with owner matching
      let mappedData = companiesResponse.map((company) => mapCompanyResponse(company, ownerMap));

      // Filter by status if provided
      if (params?.status) {
        mappedData = mappedData.filter((company) => company.status === params.status);
      }

      // Filter by search if provided
      if (params?.search) {
        const searchLower = params.search.toLowerCase();
        mappedData = mappedData.filter(
          (company) =>
            company.name.toLowerCase().includes(searchLower) ||
            company.nameAr.includes(params.search || '') ||
            company.ownerName.toLowerCase().includes(searchLower) ||
            company.ownerEmail.toLowerCase().includes(searchLower)
        );
      }

      const page = params?.page || 1;
      const pageSize = params?.pageSize || 10;
      const start = (page - 1) * pageSize;
      const end = start + pageSize;

      return {
        data: mappedData.slice(start, end),
        pagination: {
          page,
          pageSize,
          total: mappedData.length,
          totalPages: Math.ceil(mappedData.length / pageSize),
        },
      };
    } catch (error) {
      console.error('Error fetching companies:', error);
      throw error;
    }
  },

  getOwnerById: async (ownerId: string): Promise<AppUserApiResponse | null> => {
    try {
      const usersResponse = await apiClient.get<AppUserApiResponse[]>('/AppUsers/GetAllAppUsers');
      const owner = usersResponse.find(
        (user) => user.id.toString() === ownerId && user.userTypeName === 'Company'
      );
      return owner || null;
    } catch (error) {
      console.error('Error fetching owner:', error);
      throw error;
    }
  },

  getCompanyById: async (companyId: number): Promise<CompanyApiResponse | null> => {
    try {
      const response = await apiClient.get<CompanyApiResponse[]>('/Companies/GetAllCompanies');
      const company = response.find((c) => c.id === companyId);
      return company || null;
    } catch (error) {
      console.error('Error fetching company:', error);
      throw error;
    }
  },

  getCompanyCounts: async (): Promise<{ active: number; pending: number }> => {
    try {
      const response = await apiClient.get<CompanyApiResponse[]>('/Companies/GetAllCompanies');
      // For counts, we don't need owner matching, so pass undefined for ownerMap
      const mappedData = response.map((company) => mapCompanyResponse(company, undefined));
      
      const active = mappedData.filter((c) => c.status === 'active').length;
      const pending = mappedData.filter((c) => c.status === 'pending').length;

      return { active, pending };
    } catch (error) {
      console.error('Error fetching company counts:', error);
      throw error;
    }
  },

  approveCompany: async (companyId: string): Promise<void> => {
    try {
      await apiClient.patch(`/Companies/UpdateCompanyisVerified/${companyId}`, {
        isVerified: true,
      });
    } catch (error) {
      console.error('Error approving company:', error);
      throw error;
    }
  },

  rejectCompany: async (companyId: string): Promise<void> => {
    try {
      await apiClient.patch(`/Companies/UpdateCompanyisVerified/${companyId}`, {
        isVerified: false,
      });
    } catch (error) {
      console.error('Error rejecting company:', error);
      throw error;
    }
  },

  deactivateCompany: async (companyId: string): Promise<void> => {
    try {
      await apiClient.patch(`/Companies/UpdateCompanyisVerified/${companyId}`, {
        isVerified: false,
      });
    } catch (error) {
      console.error('Error deactivating company:', error);
      throw error;
    }
  },

  deleteCompany: async (companyId: string): Promise<void> => {
    try {
      await apiClient.delete(`/Companies/DeleteCompany/${companyId}`);
    } catch (error) {
      console.error('Error deleting company:', error);
      throw error;
    }
  },
};
