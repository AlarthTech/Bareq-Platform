import { COMPANY_COMMISSION_PER_BOOKING_LYD } from '../constants';

export const formatDate = (date: string | Date): string => {
  return new Date(date).toLocaleDateString('ar-LY', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    timeZone: 'Africa/Tripoli',
  });
};

export const formatDateTime = (date: string | Date): string => {
  return new Date(date).toLocaleString('ar-LY', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: 'Africa/Tripoli',
  });
};

export const formatCurrency = (amount: number, currency = 'LYD'): string => {
  return new Intl.NumberFormat('ar-LY', { style: 'currency', currency }).format(amount);
};

/** Display stored LYD amounts from API (never recompute totals). */
export const formatLyd = (amount: number): string => {
  return `${amount.toFixed(2)} د.ل`;
};

export function calculateCompanyCommission(bookingCount: number): number {
  return bookingCount * COMPANY_COMMISSION_PER_BOOKING_LYD;
}

export function isLegacyBookingPricing(booking: {
  servicePrice?: number;
  platformFeeAmount?: number;
  totalPrice?: number;
}): boolean {
  const service = booking.servicePrice ?? 0;
  const fee = booking.platformFeeAmount ?? 0;
  const total = booking.totalPrice ?? 0;
  return service === 0 && fee === 0 && total === 0;
}

export const debounce = <T extends (...args: unknown[]) => unknown>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    if (timeout) clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};

export const classNames = (...classes: (string | undefined | null | false)[]): string => {
  return classes.filter(Boolean).join(' ');
};

export { buildFileUrl } from './buildFileUrl';
