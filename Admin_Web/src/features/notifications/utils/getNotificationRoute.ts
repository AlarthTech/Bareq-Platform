import { ROUTES } from '../../../core/constants';
import type { NotificationDTO } from '../types';

const BOOKING_TYPES = new Set([
  'BookingCreated',
  'BookingConfirmed',
  'BookingAssigned',
  'BookingInProgress',
  'BookingCompleted',
  'BookingCancelled',
  'BookingRejected',
]);

export function getNotificationRoute(notification: NotificationDTO): string | null {
  const id = notification.relatedEntityId;
  if (id == null) return null;

  switch (notification.notificationTypeName) {
    case 'NewCompanyPendingApproval':
      return `${ROUTES.COMPANIES}/${id}`;
    case 'NewWorkerPendingApproval':
    case 'WorkerHealthCertificateExpired':
      return `${ROUTES.WORKERS}/${id}`;
    case 'CompanyReportedByCustomer':
    case 'WorkerReportedByCustomer':
      return `${ROUTES.REPORTS}/${id}`;
    case 'BookingReportSubmitted':
      return `${ROUTES.BOOKING_REPORTS}/${id}`;
    default:
      if (notification.notificationType === 21 && id != null) {
        return `${ROUTES.BOOKING_REPORTS}/${id}`;
      }
      if (BOOKING_TYPES.has(notification.notificationTypeName)) {
        return `${ROUTES.BOOKINGS}/${id}`;
      }
      return null;
  }
}
