export interface DashboardStats {
  totalCompanies: number;
  totalWorkers: number;
  totalCustomers: number;
  totalBookings: number;
  pendingCompanies: number;
  pendingWorkers: number;
  healthCertificates: {
    valid: number;
    almostExpired: number;
    expired: number;
  };
}

export interface ChartData {
  name: string;
  value: number;
}
