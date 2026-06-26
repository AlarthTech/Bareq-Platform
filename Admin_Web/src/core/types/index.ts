export type ApiResponse<T> = {
  data: T;
  message?: string;
  success: boolean;
};

export type PaginatedResponse<T> = {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
};

export type ApiError = {
  message: string;
  errors?: Record<string, string[]>;
  statusCode?: number;
};

export type Status = 'pending' | 'approved' | 'rejected' | 'active' | 'inactive';

export type HealthCertificateStatus = 'valid' | 'almost_expired' | 'expired';
