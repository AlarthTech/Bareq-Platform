import type { Status } from '../../core/types';

// API Response Types
export interface CompanyApiResponse {
  id: number;
  name?: string;
  nameAr?: string;
  fullName?: string;
  phone?: string;
  email?: string;
  city?: string;
  cityName?: string;
  cityId?: number;
  isActive?: boolean;
  isVerified?: boolean;
  status?: string;
  createdAt?: string;
  [key: string]: any; // Allow for other fields
}

// UI Types (mapped from API)
export interface Company {
  id: string;
  name: string;
  nameAr: string;
  ownerName: string;
  ownerEmail: string;
  ownerId?: string; // ID of the owner user from AppUsers API
  phone: string;
  email: string;
  city: string;
  status: Status;
  createdAt: string;
}
