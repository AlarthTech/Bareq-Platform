import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { bookingsApi } from '../../api/bookings.api';
import { useBookingsList } from '../../hooks/useBookingsList';
import { formatDate, formatDateTime, formatLyd, isLegacyBookingPricing } from '../../core/utils';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { BookingStatusBadge } from '../../shared/components/BookingStatusBadge';
import { useToast } from '../../shared/context/ToastContext';
import { BookingStatus, BOOKING_STATUS_LABELS } from '../../types/booking-status';
import {
  BOOKING_DISPLAY_STATUS,
  BOOKING_DISPLAY_STATUS_LABELS,
} from '../../features/bookings/utils/bookingDisplayStatus';
import type { Booking } from '../../types/api.types';
import { ROUTES } from '../../core/constants';
import { isWalletPaidBooking } from '../../features/bookings/components/BookingWalletPaymentCard';

export default function BookingsPage() {
  const [editBooking, setEditBooking] = useState<Booking | null>(null);
  const [newStatus, setNewStatus] = useState<number>(0);
  const [rejectionReason, setRejectionReason] = useState('');
  const qc = useQueryClient();
  const { showToast } = useToast();

  const {
    items,
    data,
    isLoading,
    statusFilter,
    setStatusFilter,
    displayStatusFilter,
    setDisplayStatusFilter,
    setPage,
    setPageSize,
  } = useBookingsList();

  const statusMut = useMutation({
    mutationFn: ({ id, status, rejectionReason: reason }: { id: number; status: number; rejectionReason?: string }) =>
      bookingsApi.updateStatus(id, { status, rejectionReason: reason }),
    onSuccess: (_, { id }) => {
      const b = editBooking;
      const walletMsg =
        b?.id === id && isWalletPaidBooking(b) &&
        (newStatus === BookingStatus.Canceled || newStatus === BookingStatus.Rejected)
          ? 'تم تحديث الحالة. إن كان الدفع بالمحفظة، يُعاد المبلغ تلقائياً.'
          : 'تم تحديث حالة الحجز';
      showToast(walletMsg, 'success');
      qc.invalidateQueries({ queryKey: ['bookings'] });
      setEditBooking(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const submitStatus = () => {
    if (!editBooking) return;
    if (newStatus === BookingStatus.Rejected && !rejectionReason.trim()) {
      showToast('سبب الرفض مطلوب', 'error');
      return;
    }
    statusMut.mutate({
      id: editBooking.id,
      status: newStatus,
      rejectionReason: newStatus === BookingStatus.Rejected ? rejectionReason : undefined,
    });
  };

  return (
    <div>
      <PageHeader title="الحجوزات" subtitle="إدارة جميع حجوزات المنصة" />
      <DataTable<Booking>
        isLoading={isLoading}
        data={items}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        toolbar={
          <div className="flex flex-wrap gap-3">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm"
              aria-label="فلتر حالة الخادم"
            >
              <option value="">كل حالات الخادم</option>
              {Object.entries(BookingStatus)
                .filter(([, v]) => typeof v === 'number')
                .map(([, v]) => (
                  <option key={v} value={v}>
                    {BOOKING_STATUS_LABELS[v as number]}
                  </option>
                ))}
            </select>
            <select
              value={displayStatusFilter}
              onChange={(e) => setDisplayStatusFilter(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm"
              aria-label="فلتر حالة العرض"
            >
              <option value="">كل حالات العرض</option>
              <option value={BOOKING_DISPLAY_STATUS.OnTheWay}>
                {BOOKING_DISPLAY_STATUS_LABELS[BOOKING_DISPLAY_STATUS.OnTheWay]}
              </option>
              <option value={BOOKING_DISPLAY_STATUS.CleaningStarted}>
                {BOOKING_DISPLAY_STATUS_LABELS[BOOKING_DISPLAY_STATUS.CleaningStarted]}
              </option>
            </select>
          </div>
        }
        columns={[
          { key: 'id', header: 'المعرف', render: (b) => (
            <Link to={`${ROUTES.BOOKINGS}/${b.id}`} className="text-bareq-600 hover:underline font-medium">
              #{b.id}
            </Link>
          ) },
          { key: 'userName', header: 'العميل', render: (b) => b.userName ?? `#${b.userId}` },
          { key: 'companyName', header: 'الشركة', render: (b) => b.companyName ?? `#${b.companyId}` },
          { key: 'workerName', header: 'العاملة', render: (b) => b.workerName ?? `#${b.workerId}` },
          { key: 'workTypeName', header: 'نوع العمل', render: (b) => b.workTypeName ?? '—' },
          { key: 'bookingDate', header: 'التاريخ', render: (b) => formatDate(b.bookingDate) },
          { key: 'startDate', header: 'من', render: (b) => b.startDate },
          { key: 'endDate', header: 'إلى', render: (b) => b.endDate },
          {
            key: 'status',
            header: 'الحالة',
            render: (b) => <BookingStatusBadge booking={b} showArrivalLabel />,
          },
          {
            key: 'payment',
            header: 'الدفع',
            render: (b) =>
              isWalletPaidBooking(b) ? (
                <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                  المحفظة
                </span>
              ) : (
                '—'
              ),
          },
          {
            key: 'totalPrice',
            header: 'الإجمالي',
            render: (b) =>
              isLegacyBookingPricing(b) ? (
                <span className="text-xs text-amber-700">—</span>
              ) : (
                formatLyd(b.totalPrice)
              ),
          },
          { key: 'createdAt', header: 'تاريخ الإنشاء', render: (b) => formatDateTime(b.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (b) => (
              <div className="flex gap-3 justify-end">
                <Link to={`${ROUTES.BOOKINGS}/${b.id}`} className="text-sm text-gray-600 hover:text-bareq-600">
                  عرض
                </Link>
                <button
                  type="button"
                  onClick={() => { setEditBooking(b); setNewStatus(b.status); setRejectionReason(''); }}
                  className="text-sm text-bareq-600 hover:underline"
                >
                  تغيير الحالة
                </button>
              </div>
            ),
          },
        ]}
      />

      {editBooking && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-md w-full p-6">
            <h3 className="font-bold mb-4">تحديث حالة الحجز #{editBooking.id}</h3>
            <p className="text-xs text-gray-500 mb-3">
              حالات الخادم فقط — لا يوجد إجراء «بدء التنظيف» منفصل
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
              <button type="button" onClick={() => setEditBooking(null)} className="flex-1 py-2 border rounded-lg">إلغاء</button>
              <button type="button" onClick={submitStatus} disabled={statusMut.isPending} className="flex-1 py-2 bg-bareq-600 text-white rounded-lg">
                حفظ
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
