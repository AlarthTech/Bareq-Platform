import type { BookingStatusChangedPayload, NotificationDTO } from '../types';
import { mapStatusNameToValue } from './mapBookingStatus';

const STATUS_TO_TYPE_NAME: Record<number, string> = {
  0: 'BookingCreated',
  1: 'BookingConfirmed',
  2: 'BookingInProgress',
  3: 'BookingCompleted',
  4: 'BookingCancelled',
  5: 'BookingRejected',
};

export function bookingEventToNotification(payload: BookingStatusChangedPayload): NotificationDTO {
  const statusValue = mapStatusNameToValue(payload.status);
  return {
    id: payload.id,
    userId: payload.userId ?? 0,
    title: payload.title,
    titleAr: payload.titleAr ?? payload.title,
    message: payload.message,
    messageAr: payload.messageAr ?? payload.message,
    notificationType: statusValue,
    notificationTypeName: STATUS_TO_TYPE_NAME[statusValue] ?? 'BookingConfirmed',
    relatedEntityId: payload.bookingId,
    isRead: false,
    createdAt: payload.createdAt,
  };
}
