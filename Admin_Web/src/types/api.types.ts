export interface PagedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface AppUser {
  id: number;
  fullName: string;
  phone: string;
  email: string;
  userTypeId: number;
  userTypeName: 'Admin' | 'Company' | 'Customer' | string;
  createdAt: string;
}

export interface Company {
  id: number;
  name: string;
  address?: string;
  commercialRegNo?: string;
  commercialRegisterURL?: string;
  phone: string;
  email: string;
  ownerUserId: number;
  ownerUserName?: string;
  cityId: number;
  cityName?: string;
  experienceYears: number;
  description?: string;
  isVerified: boolean;
  createdAt: string;
}

export interface Booking {
  id: number;
  userId: number;
  userName?: string;
  companyId: number;
  companyName?: string;
  workerId: number;
  workerName?: string;
  workTypeId: number;
  workTypeName?: string;
  bookingDate: string;
  startDate: string;
  endDate: string;
  address?: string;
  userLocationId?: number;
  locationName?: string;
  lat?: number;
  lng?: number;
  status: number;
  rejectionReason?: string;
  servicePrice: number;
  platformFeeAmount: number;
  totalPrice: number;
  isMonthlyPricing: boolean;
  isWorkerArrivalConfirmed?: boolean;
  workerArrivalConfirmedAt?: string | null;
  walletAmountReserved?: boolean;
  walletAmountCaptured?: boolean;
  walletCapturedAt?: string | null;
  createdAt: string;
  /** Present when booking was paid via wallet (read from API). */
  paymentMethod?: string | null;
  paymentAmount?: number | null;
  walletFeeAmount?: number | null;
  bookingTotalAmount?: number | null;
  walletRefundStatus?: number | null;
}

export interface Worker {
  id: number;
  companyId: number;
  companyName?: string;
  fullName: string;
  nationalityId: number;
  nationalityName?: string;
  age: number;
  experienceYears: number;
  isAvailable: boolean;
  profileImage?: string;
  healthCertificate?: string;
  healthCertificateURL?: string;
  healthCertificateExpiryDate?: string;
  languagesIds?: string;
  isActive: boolean;
  createdAt: string;
}

export interface WorkType {
  id: number;
  name: string;
  companyId: number;
  companyName?: string;
  startTime: string;
  endTime: string;
  isOvernight: boolean;
  price: number;
  monthlyPrice?: number;
  isMonthly: boolean;
  isActive: boolean;
  createdAt: string;
}

export interface Review {
  id: number;
  bookingId: number;
  userId: number;
  userName?: string;
  workerId: number;
  workerName?: string;
  rating: number;
  comment?: string;
  createdAt: string;
}

export interface Favorite {
  id: number;
  userId: number;
  userName?: string;
  workerId: number;
  workerName?: string;
  workerProfileImage?: string;
  companyId: number;
  companyName?: string;
  createdAt: string;
}

export interface City {
  id: number;
  name: string;
  code?: string;
  isActive: boolean;
}

export interface Nationality {
  id: number;
  name: string;
  isActive?: boolean;
}

export interface Language {
  id: number;
  name: string;
  isActive?: boolean;
}

export interface CleaningService {
  id: number;
  name: string;
  description?: string;
}

export interface UserType {
  id: number;
  name: string;
  description?: string;
}

export interface LoginResponse {
  success: boolean;
  message: string;
  token: string;
  user: AppUser;
}

export interface ToggleResponse {
  message: string;
  isVerified?: boolean;
  isActive?: boolean;
  isAvailable?: boolean;
}

export interface PaginationParams {
  page?: number;
  pageSize?: number;
}
