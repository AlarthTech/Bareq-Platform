export const BookingStatus = {
  Pending: 0,
  Approved: 1,
  OnTheWay: 2,
  Completed: 3,
  Canceled: 4,
  Rejected: 5,
} as const;

export type BookingStatusValue = (typeof BookingStatus)[keyof typeof BookingStatus];

export const BOOKING_STATUS_LABELS: Record<number, string> = {
  [BookingStatus.Pending]: 'قيد الانتظار',
  [BookingStatus.Approved]: 'مقبول',
  [BookingStatus.OnTheWay]: 'في الطريق',
  [BookingStatus.Completed]: 'مكتمل',
  [BookingStatus.Canceled]: 'ملغي',
  [BookingStatus.Rejected]: 'مرفوض',
};

export const BOOKING_STATUS_COLORS: Record<number, string> = {
  [BookingStatus.Pending]: 'bg-yellow-100 text-yellow-800',
  [BookingStatus.Approved]: 'bg-blue-100 text-blue-800',
  [BookingStatus.OnTheWay]: 'bg-purple-100 text-purple-800',
  [BookingStatus.Completed]: 'bg-green-100 text-green-800',
  [BookingStatus.Canceled]: 'bg-gray-100 text-gray-800',
  [BookingStatus.Rejected]: 'bg-red-100 text-red-800',
};
