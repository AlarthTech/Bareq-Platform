export const BookingReportStatus = {
  Open: 0,
  InReview: 1,
  Resolved: 2,
  Rejected: 3,
} as const;

export type BookingReportStatusValue =
  (typeof BookingReportStatus)[keyof typeof BookingReportStatus];

export type AdminBookingReportStatusValue = Exclude<BookingReportStatusValue, 0>;

export interface BookingReport {
  id: number;
  bookingId: number;
  customerId: number;
  customerName: string;
  companyId: number;
  companyName: string;
  workerId?: number;
  workerName?: string;
  reason: string;
  description?: string;
  status: BookingReportStatusValue;
  statusName: string;
  adminResolutionNotes?: string | null;
  resolvedByAdminId?: number | null;
  resolvedByAdminName?: string | null;
  resolvedAt?: string | null;
  createdAt: string;
  updatedAt?: string | null;
  bookingStatus: number;
  bookingStatusName: string;
}

export interface BookingReportFilters {
  status?: BookingReportStatusValue;
  bookingId?: number;
  customerId?: number;
  companyId?: number;
  workerId?: number;
  fromDate?: string;
  toDate?: string;
  page?: number;
  pageSize?: number;
}

export interface UpdateBookingReportStatusPayload {
  status: AdminBookingReportStatusValue;
  adminResolutionNotes?: string;
}

export const BOOKING_REPORT_STATUS_LABELS: Record<BookingReportStatusValue, string> = {
  [BookingReportStatus.Open]: 'مفتوح',
  [BookingReportStatus.InReview]: 'قيد المراجعة',
  [BookingReportStatus.Resolved]: 'تم الحل',
  [BookingReportStatus.Rejected]: 'مرفوض',
};

export const BOOKING_REPORT_STATUS_COLORS: Record<BookingReportStatusValue, string> = {
  [BookingReportStatus.Open]: 'bg-orange-100 text-orange-800',
  [BookingReportStatus.InReview]: 'bg-blue-100 text-blue-800',
  [BookingReportStatus.Resolved]: 'bg-green-100 text-green-800',
  [BookingReportStatus.Rejected]: 'bg-red-100 text-red-800',
};

export const ADMIN_BOOKING_REPORT_STATUS_OPTIONS: {
  value: AdminBookingReportStatusValue;
  label: string;
}[] = [
  { value: BookingReportStatus.InReview, label: BOOKING_REPORT_STATUS_LABELS[1] },
  { value: BookingReportStatus.Resolved, label: BOOKING_REPORT_STATUS_LABELS[2] },
  { value: BookingReportStatus.Rejected, label: BOOKING_REPORT_STATUS_LABELS[3] },
];

export const ADMIN_RESOLUTION_NOTES_MAX = 1000;
