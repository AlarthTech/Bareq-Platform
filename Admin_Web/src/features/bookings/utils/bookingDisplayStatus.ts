import {
  BookingStatus,
  BOOKING_STATUS_COLORS,
  BOOKING_STATUS_LABELS,
} from '../../../types/booking-status';
import type { Booking } from '../../../types/api.types';

export const BOOKING_DISPLAY_STATUS = {
  OnTheWay: 'on-the-way',
  CleaningStarted: 'cleaning-started',
} as const;

export type BookingDisplayStatusFilter =
  (typeof BOOKING_DISPLAY_STATUS)[keyof typeof BOOKING_DISPLAY_STATUS];

export const BOOKING_DISPLAY_STATUS_LABELS: Record<BookingDisplayStatusFilter, string> = {
  [BOOKING_DISPLAY_STATUS.OnTheWay]: 'في الطريق',
  [BOOKING_DISPLAY_STATUS.CleaningStarted]: 'بدأت عملية التنظيف',
};

export const CLEANING_STARTED_LABEL = 'بدأت عملية التنظيف';
export const CLEANING_STARTED_LABEL_EN = 'Cleaning Started';
export const ARRIVAL_CONFIRMED_LABEL = 'تم تأكيد الوصول';

type BookingStatusInput = Pick<Booking, 'status' | 'isWorkerArrivalConfirmed'>;

export function isCleaningStartedDisplay(booking: BookingStatusInput): boolean {
  return (
    booking.status === BookingStatus.OnTheWay &&
    Boolean(booking.isWorkerArrivalConfirmed)
  );
}

export function isOnTheWayDisplay(booking: BookingStatusInput): boolean {
  return (
    booking.status === BookingStatus.OnTheWay &&
    !booking.isWorkerArrivalConfirmed
  );
}

export function getBookingDisplayLabel(booking: BookingStatusInput): string {
  if (isCleaningStartedDisplay(booking)) {
    return CLEANING_STARTED_LABEL;
  }
  return BOOKING_STATUS_LABELS[booking.status] ?? 'غير معروف';
}

export function getBookingDisplayColor(booking: BookingStatusInput): string {
  if (isCleaningStartedDisplay(booking)) {
    return 'bg-teal-100 text-teal-800';
  }
  return BOOKING_STATUS_COLORS[booking.status] ?? 'bg-gray-100 text-gray-800';
}

export function matchesDisplayStatusFilter(
  booking: BookingStatusInput,
  filter: BookingDisplayStatusFilter
): boolean {
  if (filter === BOOKING_DISPLAY_STATUS.OnTheWay) {
    return isOnTheWayDisplay(booking);
  }
  return isCleaningStartedDisplay(booking);
}

export function getBackendStatusLabel(status: number): string {
  return BOOKING_STATUS_LABELS[status] ?? 'غير معروف';
}
