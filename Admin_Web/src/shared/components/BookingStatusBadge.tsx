import type { Booking } from '../../types/api.types';
import {
  ARRIVAL_CONFIRMED_LABEL,
  getBookingDisplayColor,
  getBookingDisplayLabel,
  isCleaningStartedDisplay,
} from '../../features/bookings/utils/bookingDisplayStatus';

interface BookingStatusBadgeProps {
  booking: Pick<Booking, 'status' | 'isWorkerArrivalConfirmed'>;
  showArrivalLabel?: boolean;
}

export function BookingStatusBadge({ booking, showArrivalLabel = false }: BookingStatusBadgeProps) {
  const label = getBookingDisplayLabel(booking);
  const color = getBookingDisplayColor(booking);
  const showArrival =
    showArrivalLabel && isCleaningStartedDisplay(booking);

  return (
    <div className="flex flex-col items-end gap-1">
      <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${color}`}>
        {label}
      </span>
      {showArrival && (
        <span className="text-[10px] text-teal-700 font-medium">{ARRIVAL_CONFIRMED_LABEL}</span>
      )}
    </div>
  );
}
