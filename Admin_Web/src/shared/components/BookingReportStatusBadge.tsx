import {
  BOOKING_REPORT_STATUS_COLORS,
  BOOKING_REPORT_STATUS_LABELS,
  type BookingReportStatusValue,
} from '../../types/booking-report';

interface BookingReportStatusBadgeProps {
  status: BookingReportStatusValue;
  label?: string;
}

export function BookingReportStatusBadge({ status, label }: BookingReportStatusBadgeProps) {
  const color = BOOKING_REPORT_STATUS_COLORS[status] ?? 'bg-gray-100 text-gray-800';
  const text = label ?? BOOKING_REPORT_STATUS_LABELS[status] ?? String(status);
  return (
    <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${color}`}>
      {text}
    </span>
  );
}
