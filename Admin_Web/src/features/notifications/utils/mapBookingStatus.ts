import { BookingStatus } from '../../../types/booking-status';

const STATUS_NAME_TO_VALUE: Record<string, number> = {
  Pending: BookingStatus.Pending,
  Approved: BookingStatus.Approved,
  Assigned: BookingStatus.Approved,
  OnTheWay: BookingStatus.OnTheWay,
  'On The Way': BookingStatus.OnTheWay,
  'In Progress': BookingStatus.OnTheWay,
  InProgress: BookingStatus.OnTheWay,
  Completed: BookingStatus.Completed,
  Canceled: BookingStatus.Canceled,
  Cancelled: BookingStatus.Canceled,
  Rejected: BookingStatus.Rejected,
  BookingCreated: BookingStatus.Pending,
  BookingConfirmed: BookingStatus.Approved,
  BookingAssigned: BookingStatus.Approved,
  BookingInProgress: BookingStatus.OnTheWay,
  BookingCompleted: BookingStatus.Completed,
  BookingCancelled: BookingStatus.Canceled,
  BookingCanceled: BookingStatus.Canceled,
  BookingRejected: BookingStatus.Rejected,
};

export function mapStatusNameToValue(status: string | number): number {
  if (typeof status === 'number') return status;
  const trimmed = status.trim();
  if (/^\d+$/.test(trimmed)) return Number(trimmed);
  return STATUS_NAME_TO_VALUE[trimmed] ?? STATUS_NAME_TO_VALUE[trimmed.replace(/\s+/g, '')] ?? BookingStatus.Pending;
}

const BOOKING_NOTIFICATION_TYPES = new Set([
  'BookingCreated',
  'BookingConfirmed',
  'BookingAssigned',
  'BookingInProgress',
  'BookingCompleted',
  'BookingCancelled',
  'BookingCanceled',
  'BookingRejected',
]);

export function isBookingNotificationType(typeName: string): boolean {
  return BOOKING_NOTIFICATION_TYPES.has(typeName);
}
