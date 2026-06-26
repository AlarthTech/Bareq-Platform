import { Link } from 'react-router-dom';
import { Eye } from 'lucide-react';
import { useBookingReports } from '../../../hooks/useBookingReports';
import { formatDateTime } from '../../../core/utils';
import { ROUTES } from '../../../core/constants';
import { BookingReportStatusBadge } from '../../../shared/components/BookingReportStatusBadge';
import type { BookingReport } from '../../../types/booking-report';

function truncate(text: string, max = 60) {
  return text.length <= max ? text : `${text.slice(0, max)}…`;
}

interface BookingReportsSectionProps {
  bookingId: number;
  onUpdateStatus?: (report: BookingReport) => void;
}

export function BookingReportsSection({ bookingId, onUpdateStatus }: BookingReportsSectionProps) {
  const { data, isLoading } = useBookingReports({
    bookingId,
    page: 1,
    pageSize: 20,
  });

  const items = data?.items ?? [];

  return (
    <section className="bg-white rounded-xl border p-6">
      <div className="flex items-center justify-between gap-4 mb-4">
        <h3 className="font-semibold text-gray-900">بلاغات الحجز</h3>
        <Link
          to={`${ROUTES.BOOKING_REPORTS}?bookingId=${bookingId}`}
          className="text-sm text-bareq-600 hover:underline"
        >
          عرض الكل
        </Link>
      </div>

      {isLoading ? (
        <p className="text-sm text-gray-500">جاري التحميل...</p>
      ) : items.length === 0 ? (
        <p className="text-sm text-gray-500">لا توجد بلاغات على هذا الحجز</p>
      ) : (
        <ul className="divide-y divide-gray-100">
          {items.map((report) => (
            <li key={report.id} className="py-3 flex flex-wrap items-center gap-3 justify-between">
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2 mb-1">
                  <Link
                    to={`${ROUTES.BOOKING_REPORTS}/${report.id}`}
                    className="font-medium text-bareq-600 hover:underline"
                  >
                    بلاغ #{report.id}
                  </Link>
                  <BookingReportStatusBadge status={report.status} label={report.statusName} />
                </div>
                <p className="text-sm text-gray-700">{truncate(report.reason, 80)}</p>
                <p className="text-xs text-gray-500 mt-1">{formatDateTime(report.createdAt)}</p>
              </div>
              <div className="flex gap-2">
                <Link
                  to={`${ROUTES.BOOKING_REPORTS}/${report.id}`}
                  className="text-sm text-gray-600 hover:text-bareq-600 p-1"
                  title="عرض"
                >
                  <Eye className="w-4 h-4" />
                </Link>
                {onUpdateStatus && (
                  <button
                    type="button"
                    onClick={() => onUpdateStatus(report)}
                    className="text-sm text-bareq-600 hover:underline"
                  >
                    تحديث الحالة
                  </button>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
