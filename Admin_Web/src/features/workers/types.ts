import type { Status, HealthCertificateStatus } from '../../core/types';

// API Response Types
export interface WorkerApiResponse {
  id: number;
  companyId: number;
  companyName: string;
  fullName: string;
  nationalityId: number;
  nationalityName: string;
  age: number;
  experienceYears: number;
  isAvailable: boolean;
  profileImage: string;
  healthCertificate: string;
  healthCertificateExpiryDate: string;
  languagesIds: string;
  isActive: boolean;
  createdAt: string;
}

// UI Types (mapped from API)
export interface Worker {
  id: string;
  name: string;
  nameAr: string;
  email: string;
  phone: string;
  nationality: string;
  companyName: string;
  companyId?: number; // ID of the company
  status: Status;
  healthCertificateStatus: HealthCertificateStatus;
  healthCertificateExpiry?: string;
  createdAt: string;
}
