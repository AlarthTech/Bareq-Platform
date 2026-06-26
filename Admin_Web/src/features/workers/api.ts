import { apiClient } from '../../core/api/client';
import type { PaginatedResponse, HealthCertificateStatus } from '../../core/types';
import type { Worker, WorkerApiResponse } from './types';

// Helper function to determine health certificate status based on expiry date
const getHealthCertificateStatus = (expiryDate: string | null | undefined): HealthCertificateStatus => {
  if (!expiryDate) return 'expired';
  
  try {
    const expiry = new Date(expiryDate);
    const now = new Date();
    const daysUntilExpiry = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    
    if (daysUntilExpiry < 0) {
      return 'expired';
    } else if (daysUntilExpiry <= 30) {
      return 'almost_expired';
    } else {
      return 'valid';
    }
  } catch (error) {
    return 'expired';
  }
};

// Helper function to map API response to UI format
const mapWorkerResponse = (apiWorker: WorkerApiResponse): Worker => {
  // Map isActive to status: true → active, false → pending
  const status: 'active' | 'pending' = apiWorker.isActive ? 'active' : 'pending';
  
  // Determine health certificate status
  const healthCertificateStatus = getHealthCertificateStatus(apiWorker.healthCertificateExpiryDate);
  
    return {
      id: apiWorker.id.toString(),
      name: apiWorker.fullName, // Using fullName as the main name
      nameAr: apiWorker.fullName, // API provides Arabic name in fullName
      email: '', // Not provided in API response
      phone: '', // Not provided in API response
      nationality: apiWorker.nationalityName || 'N/A',
      companyName: apiWorker.companyName || 'N/A',
      companyId: apiWorker.companyId,
      status,
      healthCertificateStatus,
      healthCertificateExpiry: apiWorker.healthCertificateExpiryDate,
      createdAt: apiWorker.createdAt,
    };
};

export const workersApi = {
  getWorkers: async (params?: {
    page?: number;
    pageSize?: number;
    search?: string;
    status?: string;
    healthCertificateStatus?: string;
  }): Promise<PaginatedResponse<Worker>> => {
    try {
      const response = await apiClient.get<WorkerApiResponse[]>('/Workers/GetWorkers');
      
      // Map API responses to UI format
      let mappedData = response.map(mapWorkerResponse);

      // Filter by status if provided
      if (params?.status) {
        mappedData = mappedData.filter((worker) => worker.status === params.status);
      }

      // Filter by health certificate status if provided
      if (params?.healthCertificateStatus) {
        mappedData = mappedData.filter(
          (worker) => worker.healthCertificateStatus === params.healthCertificateStatus
        );
      }

      // Filter by search if provided
      if (params?.search) {
        const searchLower = params.search.toLowerCase();
        mappedData = mappedData.filter(
          (worker) =>
            worker.name.toLowerCase().includes(searchLower) ||
            worker.nameAr.includes(params.search || '') ||
            worker.nationality.toLowerCase().includes(searchLower) ||
            worker.companyName.toLowerCase().includes(searchLower)
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
      console.error('Error fetching workers:', error);
      throw error;
    }
  },

  getWorkerCounts: async (): Promise<{
    active: number;
    pending: number;
    expiredHealthCert: number;
    almostExpiredHealthCert: number;
  }> => {
    try {
      const response = await apiClient.get<WorkerApiResponse[]>('/Workers/GetWorkers');
      const mappedData = response.map(mapWorkerResponse);

      const active = mappedData.filter((w) => w.status === 'active').length;
      const pending = mappedData.filter((w) => w.status === 'pending').length;
      const expiredHealthCert = mappedData.filter((w) => w.healthCertificateStatus === 'expired').length;
      const almostExpiredHealthCert = mappedData.filter((w) => w.healthCertificateStatus === 'almost_expired').length;

      return { active, pending, expiredHealthCert, almostExpiredHealthCert };
    } catch (error) {
      console.error('Error fetching worker counts:', error);
      throw error;
    }
  },

  approveWorker: async (workerId: string): Promise<void> => {
    try {
      await apiClient.patch(`/Workers/UpdateWorkerIsActive/${workerId}`, {
        isActive: true,
      });
    } catch (error) {
      console.error('Error approving worker:', error);
      throw error;
    }
  },

  rejectWorker: async (workerId: string): Promise<void> => {
    try {
      await apiClient.patch(`/Workers/UpdateWorkerIsActive/${workerId}`, {
        isActive: false,
      });
    } catch (error) {
      console.error('Error rejecting worker:', error);
      throw error;
    }
  },

  deactivateWorker: async (workerId: string): Promise<void> => {
    try {
      await apiClient.patch(`/Workers/UpdateWorkerIsActive/${workerId}`, {
        isActive: false,
      });
    } catch (error) {
      console.error('Error deactivating worker:', error);
      throw error;
    }
  },
};
