export const ReportStatus = {
  Pending: 0,
  UnderReview: 1,
  Resolved: 2,
  Dismissed: 3,
} as const;

export type ReportStatusValue = (typeof ReportStatus)[keyof typeof ReportStatus];

export const REPORT_STATUS_LABELS: Record<number, string> = {
  [ReportStatus.Pending]: 'قيد الانتظار',
  [ReportStatus.UnderReview]: 'قيد المراجعة',
  [ReportStatus.Resolved]: 'تم الحل',
  [ReportStatus.Dismissed]: 'مرفوض',
};

export const REPORT_STATUS_COLORS: Record<number, string> = {
  [ReportStatus.Pending]: 'bg-yellow-100 text-yellow-800',
  [ReportStatus.UnderReview]: 'bg-blue-100 text-blue-800',
  [ReportStatus.Resolved]: 'bg-green-100 text-green-800',
  [ReportStatus.Dismissed]: 'bg-gray-100 text-gray-800',
};

export const ReportTargetType = {
  Worker: 1,
  Company: 2,
} as const;

export type ReportTargetTypeValue = (typeof ReportTargetType)[keyof typeof ReportTargetType];

export interface Report {
  id: number;
  userId: number;
  userName?: string;
  targetType: ReportTargetTypeValue;
  targetTypeName: string;
  workerId?: number;
  workerName?: string;
  companyId?: number;
  companyName?: string;
  description: string;
  status: ReportStatusValue;
  statusName: string;
  adminNotes?: string;
  createdAt: string;
  updatedAt?: string;
}

export type ReportStatusUpdate = {
  status: ReportStatusValue;
  adminNotes?: string;
};
