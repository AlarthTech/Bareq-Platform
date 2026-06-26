import { apiClient } from '../../core/api/client';
import type { PaginatedResponse } from '../../core/types';
import type { Booking, BookingApiResponse } from './types';

// Helper function to map status number to status string
const mapStatus = (status: number): 'pending' | 'confirmed' | 'completed' | 'cancelled' => {
  // Map status numbers to status strings
  // You may need to adjust these mappings based on your API's status values
  switch (status) {
    case 0:
      return 'pending';
    case 1:
      return 'confirmed';
    case 2:
      return 'completed';
    case 3:
      return 'cancelled';
    default:
      return 'pending';
  }
};

// Helper function to format time from date string
const formatTime = (dateString: string): string => {
  if (!dateString) return '';
  try {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
  } catch {
    return '';
  }
};

// Helper function to map API response to UI format
const mapBookingResponse = (apiBooking: BookingApiResponse): Booking => {
  return {
    id: apiBooking.id.toString(),
    customerName: apiBooking.userName || 'Unknown Customer',
    customerEmail: '', // Not provided in API response
    companyName: apiBooking.companyName || 'N/A',
    workerName: apiBooking.workerName || 'N/A',
    serviceDate: apiBooking.bookingDate || apiBooking.startDate || '',
    serviceTime: apiBooking.startDate ? formatTime(apiBooking.startDate) : '',
    status: mapStatus(apiBooking.status),
    totalAmount: 0, // Not provided in API response
    createdAt: apiBooking.createdAt || new Date().toISOString(),
  };
};

export const bookingsApi = {
  getBookings: async (params?: {
    page?: number;
    pageSize?: number;
    search?: string;
    status?: string;
    dateFrom?: string;
    dateTo?: string;
    companyId?: string;
    workerId?: string;
  }): Promise<PaginatedResponse<Booking>> => {
    try {
      const response = await apiClient.get<BookingApiResponse[]>('/Bookings/GetBookings');

      // Map API responses to UI format
      let mappedData = response.map(mapBookingResponse);

      // Filter by status if provided
      if (params?.status) {
        mappedData = mappedData.filter((booking) => booking.status === params.status);
      }

      // Filter by search if provided
      if (params?.search) {
        const searchLower = params.search.toLowerCase();
        mappedData = mappedData.filter(
          (booking) => {
            const originalBooking = response.find((b) => b.id.toString() === booking.id);
            return (
              booking.customerName.toLowerCase().includes(searchLower) ||
              booking.companyName.toLowerCase().includes(searchLower) ||
              booking.workerName.toLowerCase().includes(searchLower) ||
              originalBooking?.address?.toLowerCase().includes(searchLower) ||
              false
            );
          }
        );
      }

      // Filter by date range if provided
      if (params?.dateFrom) {
        mappedData = mappedData.filter((booking) => {
          const bookingDate = new Date(booking.serviceDate);
          const fromDate = new Date(params.dateFrom!);
          return bookingDate >= fromDate;
        });
      }

      if (params?.dateTo) {
        mappedData = mappedData.filter((booking) => {
          const bookingDate = new Date(booking.serviceDate);
          const toDate = new Date(params.dateTo!);
          return bookingDate <= toDate;
        });
      }

      // Filter by companyId if provided
      if (params?.companyId) {
        mappedData = mappedData.filter((booking) => {
          const originalBooking = response.find((b) => b.id.toString() === booking.id);
          return originalBooking?.companyId.toString() === params.companyId;
        });
      }

      // Filter by workerId if provided
      if (params?.workerId) {
        mappedData = mappedData.filter((booking) => {
          const originalBooking = response.find((b) => b.id.toString() === booking.id);
          return originalBooking?.workerId.toString() === params.workerId;
        });
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
      console.error('Error fetching bookings:', error);
      throw error;
    }
  },
};
