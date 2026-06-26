import type { Booking } from '../../../types/api.types';
import { formatDateTime } from '../../../core/utils';
import { BookingStatus } from '../../../types/booking-status';
import {
  CLEANING_STARTED_LABEL,
  CLEANING_STARTED_LABEL_EN,
  getBackendStatusLabel,
} from '../utils/bookingDisplayStatus';

interface BookingArrivalConfirmationCardProps {
  booking: Booking;
}

function Row({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-4 py-2 text-sm border-b border-gray-100 last:border-0">
      <dt className="text-gray-500 shrink-0">{label}</dt>
      <dd className="font-medium text-right">{value}</dd>
    </div>
  );
}

export function BookingArrivalConfirmationCard({ booking }: BookingArrivalConfirmationCardProps) {
  const confirmed = Boolean(booking.isWorkerArrivalConfirmed);
  const onTheWay = booking.status === BookingStatus.OnTheWay;

  return (
    <section className="bg-white rounded-xl border p-6">
      <h3 className="font-semibold text-gray-900 mb-4">تأكيد الوصول</h3>

      <dl>
        <Row label="تم تأكيد الوصول" value={confirmed ? 'نعم' : 'لا'} />
        <Row label="أكّده" value={confirmed ? 'العميلة' : '—'} />
        <Row
          label="وقت التأكيد"
          value={
            booking.workerArrivalConfirmedAt
              ? formatDateTime(booking.workerArrivalConfirmedAt)
              : '—'
          }
        />
        <Row
          label="حالة العرض"
          value={
            onTheWay && confirmed ? (
              <span>
                {CLEANING_STARTED_LABEL}
                <span className="text-gray-400 font-normal text-xs mr-1">
                  ({CLEANING_STARTED_LABEL_EN})
                </span>
              </span>
            ) : onTheWay ? (
              'في الطريق'
            ) : (
              '—'
            )
          }
        />
        <Row
          label="حالة الخادم"
          value={
            onTheWay ? (
              <span>
                OnTheWay / {getBackendStatusLabel(BookingStatus.OnTheWay)}
              </span>
            ) : (
              `${booking.status} / ${getBackendStatusLabel(booking.status)}`
            )
          }
        />
      </dl>

      <p
        className={`mt-4 text-sm rounded-lg px-4 py-3 ${
          confirmed
            ? 'bg-teal-50 text-teal-900 border border-teal-100'
            : 'bg-amber-50 text-amber-900 border border-amber-100'
        }`}
      >
        {confirmed
          ? 'تم تأكيد وصول العاملة من قبل العميلة وبدأت الخدمة.'
          : 'في انتظار تأكيد وصول العاملة من العميلة.'}
      </p>
    </section>
  );
}
