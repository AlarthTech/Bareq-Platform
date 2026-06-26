import type { Booking } from '../../../types/api.types';
import { formatDateTime, formatLyd } from '../../../core/utils';
import { isCleaningStartedDisplay } from '../utils/bookingDisplayStatus';

export function isWalletPaidBooking(booking: Booking): boolean {
  return (
    booking.paymentMethod === 'Wallet' ||
    Boolean(booking.walletAmountReserved) ||
    Boolean(booking.walletAmountCaptured)
  );
}

function StatusBadge({ label, color }: { label: string; color: string }) {
  return (
    <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${color}`}>
      {label}
    </span>
  );
}

function YesNo({ value }: { value?: boolean }) {
  return <span>{value ? 'نعم' : 'لا'}</span>;
}

interface BookingWalletPaymentCardProps {
  booking: Booking;
}

export function BookingWalletPaymentCard({ booking }: BookingWalletPaymentCardProps) {
  const isWallet = isWalletPaidBooking(booking);
  const bookingTotal = booking.bookingTotalAmount ?? booking.totalPrice;
  const walletFee = booking.walletFeeAmount ?? 0;
  const refundStatus = booking.walletRefundStatus ?? 0;
  const arrivalConfirmed = isCleaningStartedDisplay(booking);

  return (
    <section className="bg-white rounded-xl border p-6">
      <h3 className="font-semibold text-gray-900 mb-4">الدفع</h3>

      <dl className="space-y-3 text-sm">
        <div className="flex justify-between gap-4">
          <dt className="text-gray-500">طريقة الدفع</dt>
          <dd className="font-medium">{booking.paymentMethod ?? '—'}</dd>
        </div>

        {isWallet && (
          <>
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500">محجوز من المحفظة</dt>
              <dd className="font-medium">
                <YesNo value={booking.walletAmountReserved} />
              </dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500">تم الخصم من المحفظة</dt>
              <dd className="font-medium">
                <YesNo value={booking.walletAmountCaptured} />
              </dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500">تاريخ الخصم</dt>
              <dd className="font-medium">
                {booking.walletCapturedAt
                  ? formatDateTime(booking.walletCapturedAt)
                  : '—'}
              </dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500">إجمالي الحجز</dt>
              <dd className="font-medium tabular-nums">{formatLyd(bookingTotal)}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500">رسوم المحفظة</dt>
              <dd className="font-medium tabular-nums">{formatLyd(walletFee)}</dd>
            </div>
            <div className="flex justify-between gap-4 border-t pt-3">
              <dt className="text-gray-500">حالة الاسترداد</dt>
              <dd>
                {refundStatus === 1 ? (
                  <StatusBadge label="تم الاسترداد" color="bg-green-100 text-green-800" />
                ) : (
                  <StatusBadge label="لا يوجد" color="bg-gray-100 text-gray-700" />
                )}
              </dd>
            </div>
          </>
        )}
      </dl>

      {isWallet && arrivalConfirmed && (
        <p className="text-sm text-teal-800 bg-teal-50 border border-teal-100 rounded-lg px-4 py-3 mt-4">
          تم تأكيد الوصول وتم خصم قيمة الحجز من المحفظة.
        </p>
      )}

      {isWallet && !arrivalConfirmed && (
        <p className="text-xs text-gray-500 mt-4 leading-relaxed">
          عند إنشاء الحجز بالمحفظة يُحجَز المبلغ. يُخصَم عند اكتمال الحجز أو تأكيد وصول العميل.
          عند الإلغاء أو الرفض يُحرَّر الحجز أو يُسترد المبلغ تلقائياً.
        </p>
      )}
    </section>
  );
}
