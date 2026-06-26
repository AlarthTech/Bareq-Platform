import type { Booking } from '../../../types/api.types';
import { formatLyd, isLegacyBookingPricing } from '../../../core/utils';

interface BookingPricingCardProps {
  booking: Booking;
}

function PriceRow({
  label,
  value,
  bold = false,
}: {
  label: string;
  value: string;
  bold?: boolean;
}) {
  return (
    <div
      className={`flex items-center justify-between gap-4 py-2 ${
        bold ? 'font-semibold text-gray-900' : 'text-gray-700'
      }`}
    >
      <span className="text-sm text-gray-500">{label}</span>
      <span className="text-sm tabular-nums">{value}</span>
    </div>
  );
}

export function BookingPricingCard({ booking }: BookingPricingCardProps) {
  const legacy = isLegacyBookingPricing(booking);

  return (
    <section className="bg-white rounded-xl border p-6">
      <div className="flex flex-wrap items-center gap-2 mb-4">
        <h3 className="font-semibold text-gray-900">تفاصيل السعر</h3>
        {booking.isMonthlyPricing && !legacy && (
          <span className="inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
            تسعير شهري
          </span>
        )}
      </div>

      {legacy ? (
        <span className="inline-flex px-3 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
          تسعير قديم — غير متوفر
        </span>
      ) : (
        <>
          <PriceRow label="سعر الخدمة" value={formatLyd(booking.servicePrice)} />
          <PriceRow label="رسوم المنصة" value={formatLyd(booking.platformFeeAmount)} />
          <div className="border-t border-gray-200 my-2" />
          <PriceRow label="الإجمالي" value={formatLyd(booking.totalPrice)} bold />
        </>
      )}
    </section>
  );
}
