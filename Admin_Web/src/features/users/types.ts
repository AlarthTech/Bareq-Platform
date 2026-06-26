import type { Status } from '../../core/types';

// API Response Types
export interface AppUserApiResponse {
  id: number;
  fullName: string;
  phone: string;
  email: string;
  userTypeId: number;
  userTypeName: string;
  createdAt: string;
}

// UI Types
export interface CompanyOwner {
  id: string;
  name: string;
  email: string;
  phone: string;
  companyName: string;
  status: Status;
  createdAt: string;
}

export interface Customer {
  id: string;
  name: string;
  email: string;
  phone: string;
  status: Status;
  totalBookings: number;
  createdAt: string;
}
