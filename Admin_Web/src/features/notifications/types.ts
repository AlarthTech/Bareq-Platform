export interface NotificationDTO {
  id: number;
  userId: number;
  title: string;
  titleAr: string;
  message: string;
  messageAr: string;
  notificationType: number;
  notificationTypeName: string;
  relatedEntityId: number | null;
  isRead: boolean;
  createdAt: string;
}

/** Real-time payload from SignalR BookingStatusChanged event. */
export interface BookingStatusChangedPayload {
  id: number;
  title: string;
  titleAr?: string;
  message: string;
  messageAr?: string;
  bookingId: number;
  status: string | number;
  createdAt: string;
  userId?: number;
  rejectionReason?: string;
}

export type NotificationDateGroup = 'today' | 'yesterday' | 'earlier';

export const NOTIFICATION_GROUP_LABELS: Record<NotificationDateGroup, string> = {
  today: 'اليوم',
  yesterday: 'أمس',
  earlier: 'سابقاً',
};
