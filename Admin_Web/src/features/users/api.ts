import { apiClient } from '../../core/api/client';
import type { PaginatedResponse } from '../../core/types';
import type { CompanyOwner, Customer, AppUserApiResponse } from './types';

// Helper function to map API response to Customer format
const mapCustomerResponse = (apiUser: AppUserApiResponse): Customer => ({
  id: apiUser.id.toString(),
  name: apiUser.fullName,
  email: apiUser.email,
  phone: apiUser.phone,
  status: 'active' as const, // Default to active, adjust based on your business logic
  totalBookings: 0, // This would need to come from a separate API call
  createdAt: apiUser.createdAt,
});

export const usersApi = {
  getCompanyOwners: async (params?: {
    page?: number;
    pageSize?: number;
    search?: string;
  }): Promise<PaginatedResponse<CompanyOwner>> => {
    // Mock data for company owners - replace when API is available
    const mockData: CompanyOwner[] = Array.from({ length: 50 }, (_, i) => ({
      id: `owner-${i + 1}`,
      name: `Owner ${i + 1}`,
      email: `owner${i + 1}@example.com`,
      phone: `+966501234${String(i).padStart(4, '0')}`,
      companyName: `Company ${i + 1}`,
      status: i % 3 === 0 ? 'active' : i % 3 === 1 ? 'inactive' : 'pending',
      createdAt: new Date(Date.now() - i * 86400000).toISOString(),
    }));

    const page = params?.page || 1;
    const pageSize = params?.pageSize || 10;
    const start = (page - 1) * pageSize;
    const end = start + pageSize;

    return {
      data: mockData.slice(start, end),
      pagination: {
        page,
        pageSize,
        total: mockData.length,
        totalPages: Math.ceil(mockData.length / pageSize),
      },
    };
  },

  getCustomers: async (params?: {
    page?: number;
    pageSize?: number;
    search?: string;
  }): Promise<PaginatedResponse<Customer>> => {
    try {
      const response = await apiClient.get<AppUserApiResponse[]>('/AppUsers/GetAllAppUsers');
      
      // Filter only customers (userTypeName === "Customer")
      const customers = response.filter((user) => user.userTypeName === 'Customer');
      
      // Map to Customer format
      let mappedData = customers.map(mapCustomerResponse);

      // Filter by search if provided
      if (params?.search) {
        const searchLower = params.search.toLowerCase();
        mappedData = mappedData.filter(
          (customer) =>
            customer.name.toLowerCase().includes(searchLower) ||
            customer.email.toLowerCase().includes(searchLower) ||
            customer.phone.includes(params.search || '')
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
      console.error('Error fetching customers:', error);
      throw error;
    }
  },

  updateUserStatus: async (_userId: string, _status: string): Promise<void> => {
    // Mock - replace with actual API call
    await new Promise((resolve) => setTimeout(resolve, 500));
    // Uncomment when API is ready:
    // await apiClient.patch(`/users/${userId}/status`, { status });
  },
};
