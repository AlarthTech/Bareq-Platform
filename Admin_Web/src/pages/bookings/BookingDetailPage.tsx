import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useBooking } from '../../hooks/useBooking';
import { bookingsApi } from '../../api/bookings.api';
import { formatDate, formatDateTime } from '../../core/utils';
import { ROUTES } from '../../core/constants';
import { PageHeader } from '../../shared/components/PageHeader';
import { BookingStatusBadge } from '../../shared/components/BookingStatusBadge';
import { Loader } from '../../shared/components/Loader';
import { Button } from '../../shared/ui/Button';
import { useToast } from '../../shared/context/ToastContext';
import { BookingStatus, BOOKING_STATUS_LABELS } from '../../types/booking-status';
import {
  getBackendStatusLabel,
  getBookingDisplayLabel,
  isCleaningStartedDisplay,
} from '../../features/bookings/utils/bookingDisplayStatus';
import { BookingPricingCard } from '../../features/bookings/components/BookingPricingCard';
import { BookingArrivalConfirmationCard } from '../../features/bookings/components/BookingArrivalConfirmationCard';
import { BookingReportsSection } from '../../features/booking-reports/components/BookingReportsSection';
import { UpdateBookingReportStatusModal } from '../../features/booking-reports/components/UpdateBookingReportStatusModal';
import { useUpdateBookingReportStatus } from '../../hooks/useBookingReports';
import type { BookingReport } from '../../types/booking-report';
import {
  BookingWalletPaymentCard,
  isWalletPaidBooking,
} from '../../features/bookings/components/BookingWalletPaymentCard';

const STATUS_TIMELINE = [
  BookingStatus.Pending,
  BookingStatus.Approved,
  BookingStatus.OnTheWay,
  BookingStatus.Completed,
] as const;

function timelineStepLabel(step: number, booking: { status: number; isWorkerArrivalConfirmed?: boolean }): string {
  if (step === BookingStatus.OnTheWay && booking.status === BookingStatus.OnTheWay) {
    return getBookingDisplayLabel(booking);
  }
  return BOOKING_STATUS_LABELS[step];
}

export default function BookingDetailPage() {
  const { id } = useParams<{ id: string }>();
  const bookingId = Number(id);
  const navigate = useNavigate();
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data: booking, isLoading, isError } = useBooking(bookingId);

  const [statusModalOpen, setStatusModalOpen] = useState(false);
  const [newStatus, setNewStatus] = useState<number>(BookingStatus.Pending);
  const [rejectionReason, setRejectionReason] = useState('');
  const [editBookingReport, setEditBookingReport] = useState<BookingReport | null>(null);

  const statusMut = useMutation({
    mutationFn: ({ status, rejectionReason: reason }: { status: number; rejectionReason?: string }) =>
      bookingsApi.updateStatus(bookingId, { status, rejectionReason: reason }),
    onSuccess: () => {
      const walletMsg = booking && isWalletPaidBooking(booking)
        ? 'تم تحديث الحالة. إن كان الدفع بالمحفظة، يُعاد المبلغ تلقائياً.'
        : 'تم تحديث حالة الحجز';
      showToast(walletMsg, 'success');
      qc.invalidateQueries({ queryKey: ['bookings', bookingId] });
      qc.invalidateQueries({ queryKey: ['bookings'] });
      setStatusModalOpen(false);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const updateBookingReportMutation = useUpdateBookingReportStatus();

  const handleBookingReportStatus = async (payload: {
    status: 1 | 2 | 3;
    adminResolutionNotes?: string;
  }) => {
    if (!editBookingReport) return;
    try {
      await updateBookingReportMutation.mutateAsync({
        id: editBookingReport.id,
        ...payload,
      });
      showToast('تم تحديث حالة البلاغ', 'success');
      setEditBookingReport(null);
    } catch (e) {
      showToast(e instanceof Error ? e.message : 'حدث خطأ', 'error');
    }
  };

  if (isLoading) return <Loader />;

  if (isError || !booking) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-600 mb-4">الحجز غير موجود</p>
        <Link to={ROUTES.BOOKINGS} className="text-bareq-600 hover:underline">
          العودة إلى الحجوزات
        </Link>
      </div>
    );
  }

  const openStatusModal = () => {
    setNewStatus(booking.status);
    setRejectionReason(booking.rejectionReason ?? '');
    setStatusModalOpen(true);
  };

  const submitStatus = () => {
    if (newStatus === BookingStatus.Rejected && !rejectionReason.trim()) {
      showToast('سبب الرفض مطلوب', 'error');
      return;
    }
    statusMut.mutate({
      status: newStatus,
      rejectionReason: newStatus === BookingStatus.Rejected ? rejectionReason : undefined,
    });
  };

  const isTerminal =
    booking.status === BookingStatus.Canceled || booking.status === BookingStatus.Rejected;

  return (
    <div className="max-w-3xl space-y-6">
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <Link to={ROUTES.BOOKINGS} className="hover:text-bareq-600">
          الحجوزات
        </Link>
        <ArrowRight className="w-4 h-4 rotate-180" />
        <span>حجز #{booking.id}</span>
      </div>

      <PageHeader
        title={`حجز #${booking.id}`}
        subtitle="تفاصيل الحجز — يتحدّث تلقائياً عند تغيّر الحالة"
        actions={
          !isTerminal ? (
            <Button type="button" onClick={openStatusModal}>
              تغيير الحالة
            </Button>
          ) : undefined
        }
      />

      <BookingPricingCard booking={booking} />
      <BookingArrivalConfirmationCard booking={booking} />
      <BookingWalletPaymentCard booking={booking} />
      <BookingReportsSection
        bookingId={booking.id}
        onUpdateStatus={setEditBookingReport}
      />

      <div className="bg-white rounded-xl border p-6 space-y-4">
        <div className="flex items-center justify-between gap-4">
          <span className="text-sm text-gray-500">حالة العرض</span>
          <BookingStatusBadge booking={booking} showArrivalLabel />
        </div>
        <div className="flex items-center justify-between gap-4 text-sm">
          <span className="text-gray-500">حالة الخادم</span>
          <span className="font-medium text-gray-700">
            {booking.status} — {getBackendStatusLabel(booking.status)}
          </span>
        </div>

        <dl className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
          <div>
            <dt className="text-gray-500">العميل</dt>
            <dd className="font-medium">{booking.userName ?? `#${booking.userId}`}</dd>
          </div>
          <div>
            <dt className="text-gray-500">الشركة</dt>
            <dd className="font-medium">{booking.companyName ?? `#${booking.companyId}`}</dd>
          </div>
          <div>
            <dt className="text-gray-500">العاملة</dt>
            <dd className="font-medium">{booking.workerName ?? `#${booking.workerId}`}</dd>
          </div>
          <div>
            <dt className="text-gray-500">نوع العمل</dt>
            <dd className="font-medium">{booking.workTypeName ?? '—'}</dd>
          </div>
          <div>
            <dt className="text-gray-500">تاريخ الحجز</dt>
            <dd className="font-medium">{formatDate(booking.bookingDate)}</dd>
          </div>
          <div>
            <dt className="text-gray-500">الوقت</dt>
            <dd className="font-medium">
              {booking.startDate} — {booking.endDate}
            </dd>
          </div>
          {booking.address && (
            <div className="sm:col-span-2">
              <dt className="text-gray-500">العنوان</dt>
              <dd className="font-medium">{booking.address}</dd>
            </div>
          )}
          <div>
            <dt className="text-gray-500">تاريخ الإنشاء</dt>
            <dd className="font-medium">{formatDateTime(booking.createdAt)}</dd>
          </div>
        </dl>

        {booking.rejectionReason && (
          <div className="rounded-lg bg-red-50 text-red-800 text-sm p-3">
            <strong>سبب الرفض:</strong> {booking.rejectionReason}
          </div>
        )}
      </div>

      <section className="bg-white rounded-xl border p-6">
        <h3 className="font-semibold mb-4">مسار الحالة</h3>
        <ol className="space-y-3">
          {STATUS_TIMELINE.map((step) => {
            const reached =
              booking.status === step ||
              (step === BookingStatus.Approved && booking.status > BookingStatus.Approved) ||
              (step === BookingStatus.OnTheWay && booking.status > BookingStatus.OnTheWay);
            const isCurrent = booking.status === step;
            const stepLabel = timelineStepLabel(step, booking);
            const cleaningStarted =
              step === BookingStatus.OnTheWay && isCurrent && isCleaningStartedDisplay(booking);

            return (
              <li key={step} className="flex items-center gap-3">
                <span
                  className={`w-3 h-3 rounded-full shrink-0 transition-colors ${
                    isCurrent
                      ? cleaningStarted
                        ? 'bg-teal-600 ring-4 ring-teal-100'
                        : 'bg-bareq-600 ring-4 ring-bareq-100'
                      : reached
                        ? 'bg-green-500'
                        : 'bg-gray-200'
                  }`}
                />
                <span
                  className={
                    isCurrent
                      ? cleaningStarted
                        ? 'font-semibold text-teal-700'
                        : 'font-semibold text-bareq-700'
                      : 'text-gray-700'
                  }
                >
                  {stepLabel}
                </span>
                {cleaningStarted && (
                  <span className="text-xs text-gray-500">(OnTheWay)</span>
                )}
              </li>
            );
          })}
          {(booking.status === BookingStatus.Canceled ||
            booking.status === BookingStatus.Rejected) && (
            <li className="flex items-center gap-3">
              <span className="w-3 h-3 rounded-full bg-red-500 shrink-0" />
              <span className="font-semibold text-red-700">
                {BOOKING_STATUS_LABELS[booking.status]}
              </span>
            </li>
          )}
        </ol>
      </section>

      <div className="flex gap-2">
        <Button type="button" variant="outline" onClick={() => navigate(ROUTES.BOOKINGS)}>
          العودة للقائمة
        </Button>
      </div>

      {statusModalOpen && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-md w-full p-6">
            <h3 className="font-bold mb-4">تحديث حالة الحجز #{booking.id}</h3>
            <p className="text-xs text-gray-500 mb-3">
              حالات الخادم فقط (0–5) — تأكيد الوصول يتم من تطبيق العميل
            </p>
            <select
              value={newStatus}
              onChange={(e) => setNewStatus(Number(e.target.value))}
              className="w-full border rounded-lg px-3 py-2 mb-3"
            >
              {Object.entries(BookingStatus)
                .filter(([, v]) => typeof v === 'number')
                .map(([, v]) => (
                  <option key={v} value={v as number}>
                    {BOOKING_STATUS_LABELS[v as number]}
                  </option>
                ))}
            </select>
            {newStatus === BookingStatus.Rejected && (
              <textarea
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                placeholder="سبب الرفض"
                className="w-full border rounded-lg px-3 py-2 mb-3"
                rows={3}
              />
            )}
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setStatusModalOpen(false)}
                className="flex-1 py-2 border rounded-lg"
              >
                إلغاء
              </button>
              <button
                type="button"
                onClick={submitStatus}
                disabled={statusMut.isPending}
                className="flex-1 py-2 bg-bareq-600 text-white rounded-lg disabled:opacity-50"
              >
                حفظ
              </button>
            </div>
          </div>
        </div>
      )}

      <UpdateBookingReportStatusModal
        report={editBookingReport}
        isOpen={editBookingReport != null}
        onClose={() => setEditBookingReport(null)}
        onSubmit={handleBookingReportStatus}
        isLoading={updateBookingReportMutation.isPending}
      />
    </div>
  );
}
