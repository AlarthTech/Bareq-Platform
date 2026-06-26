// API Response Types
export interface BookingApiResponse {
  id: number;
  userId: number;
  userName: string;
  companyId: number;
  companyName: string;
  workerId: number;
  workerName: string;
  workTypeId: number;
  workTypeName: string;
  bookingDate: string;
  startDate: string;
  endDate: string;
  address: string;
  status: number;
  createdAt: string;
}

// UI Types (mapped from API)
export interface Booking {
  id: string;
  customerName: string;
  customerEmail: string;
  companyName: string;
  workerName: string;
  serviceDate: string;
  serviceTime: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  totalAmount: number;
  createdAt: string;
}
