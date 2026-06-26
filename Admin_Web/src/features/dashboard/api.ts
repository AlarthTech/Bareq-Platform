import { apiClient } from '../../core/api/client';
import type { DashboardStats } from './types';
import type { CompanyApiResponse } from '../companies/types';
import type { AppUserApiResponse } from '../users/types';
import type { WorkerApiResponse } from '../workers/types';

// Helper function to determine health certificate status based on expiry date
const getHealthCertificateStatus = (expiryDate: string | null | undefined): 'valid' | 'almost_expired' | 'expired' => {
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

// Booking API Response type (minimal structure for counting)
interface BookingApiResponse {
  id: number | string;
  [key: string]: any; // Allow for other fields
}

export const dashboardApi = {
  getStats: async (): Promise<DashboardStats> => {
    try {
      // Fetch companies, users, workers, and bookings in parallel
      const [companiesResponse, usersResponse, workersResponse, bookingsResponse] = await Promise.all([
        apiClient.get<CompanyApiResponse[]>('/Companies/GetAllCompanies'),
        apiClient.get<AppUserApiResponse[]>('/AppUsers/GetAllAppUsers'),
        apiClient.get<WorkerApiResponse[]>('/Workers/GetWorkers'),
        apiClient.get<BookingApiResponse[]>('/Bookings/GetBookings'),
      ]);

      // Count only customers (userTypeName === "Customer")
      const customers = usersResponse.filter((user) => user.userTypeName === 'Customer');
      
      // Count active and pending companies based on isVerified
      // isVerified: true → active
      // isVerified: false → pending
      const pendingCompanies = companiesResponse.filter((c) => c.isVerified === false).length;

      // Calculate worker stats from real data
      const totalWorkers = workersResponse.length;
      const pendingWorkers = workersResponse.filter((w) => !w.isActive).length;
      
      // Calculate health certificate stats
      const healthCertStatuses = workersResponse.map((w) =>
        getHealthCertificateStatus(w.healthCertificateExpiryDate)
      );
      const healthCertificates = {
        valid: healthCertStatuses.filter((s) => s === 'valid').length,
        almostExpired: healthCertStatuses.filter((s) => s === 'almost_expired').length,
        expired: healthCertStatuses.filter((s) => s === 'expired').length,
      };

      // Get total bookings count from API
      const totalBookings = bookingsResponse.length;

      return {
        totalCompanies: companiesResponse.length,
        totalWorkers,
        totalCustomers: customers.length,
        totalBookings,
        pendingCompanies,
        pendingWorkers,
        healthCertificates,
      };
    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
      // Return mock data on error
      return {
        totalCompanies: 0,
        totalWorkers: 0,
        totalCustomers: 0,
        totalBookings: 0,
        pendingCompanies: 0,
        pendingWorkers: 0,
        healthCertificates: {
          valid: 0,
          almostExpired: 0,
          expired: 0,
        },
      };
    }
  },
};
