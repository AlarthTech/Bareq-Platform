import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { useBookingReport, useUpdateBookingReportStatus } from '../../hooks/useBookingReports';
import { formatDateTime } from '../../core/utils';
import { getErrorMessage } from '../../core/utils/getErrorMessage';
import { ROUTES } from '../../core/constants';
import { PageHeader } from '../../shared/components/PageHeader';
import { BookingReportStatusBadge } from '../../shared/components/BookingReportStatusBadge';
import { Loader } from '../../shared/components/Loader';
import { Button } from '../../shared/ui/Button';
import { useToast } from '../../shared/context/ToastContext';
import { UpdateBookingReportStatusModal } from '../../features/booking-reports/components/UpdateBookingReportStatusModal';
import { BookingReportStatus } from '../../types/booking-report';

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-4 py-2 text-sm border-b border-gray-100 last:border-0">
      <dt className="text-gray-500 shrink-0">{label}</dt>
      <dd className="font-medium text-right">{value}</dd>
    </div>
  );
}

export default function BookingReportDetailPage() {
  const { id } = useParams<{ id: string }>();
  const reportId = Number(id);
  const navigate = useNavigate();
  const { showToast } = useToast();

  const { data: report, isLoading, isError } = useBookingReport(reportId);
  const updateMutation = useUpdateBookingReportStatus();
  const [statusModalOpen, setStatusModalOpen] = useState(false);

  if (isLoading) return <Loader />;

  if (isError || !report) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-600 mb-4">البلاغ غير موجود</p>
        <Link to={ROUTES.BOOKING_REPORTS} className="text-bareq-600 hover:underline">
          العودة إلى بلاغات الحجوزات
        </Link>
      </div>
    );
  }

  const isTerminal =
    report.status === BookingReportStatus.Resolved ||
    report.status === BookingReportStatus.Rejected;

  const handleUpdateStatus = async (payload: {
    status: 1 | 2 | 3;
    adminResolutionNotes?: string;
  }) => {
    try {
      await updateMutation.mutateAsync({ id: report.id, ...payload });
      showToast('تم تحديث حالة البلاغ', 'success');
      setStatusModalOpen(false);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  return (
    <div className="max-w-3xl space-y-6">
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <Link to={ROUTES.BOOKING_REPORTS} className="hover:text-bareq-600">
          بلاغات الحجوزات
        </Link>
        <ArrowRight className="w-4 h-4 rotate-180" />
        <span>بلاغ #{report.id}</span>
      </div>

      <PageHeader
        title={`بلاغ حجز #${report.id}`}
        subtitle={`أُنشئ: ${formatDateTime(report.createdAt)}${
          report.updatedAt ? ` · آخر تحديث: ${formatDateTime(report.updatedAt)}` : ''
        }`}
        actions={
          <div className="flex items-center gap-3">
            <BookingReportStatusBadge status={report.status} label={report.statusName} />
            <Button type="button" onClick={() => setStatusModalOpen(true)}>
              تحديث الحالة
            </Button>
          </div>
        }
      />

      <section className="bg-white rounded-xl border p-6">
        <h3 className="font-semibold mb-4">سياق الحجز</h3>
        <dl>
          <InfoRow
            label="الحجز"
            value={
              <Link
                to={`${ROUTES.BOOKINGS}/${report.bookingId}`}
                className="text-bareq-600 hover:underline"
              >
                #{report.bookingId}
              </Link>
            }
          />
          <InfoRow
            label="حالة الحجز"
            value={
              <span className="inline-flex px-2 py-0.5 rounded-full text-xs bg-gray-100 text-gray-800">
                {report.bookingStatusName}
              </span>
            }
          />
          <InfoRow
            label="الشركة"
            value={`${report.companyName} (#${report.companyId})`}
          />
          <InfoRow
            label="العاملة"
            value={
              report.workerName
                ? `${report.workerName}${report.workerId ? ` (#${report.workerId})` : ''}`
                : '—'
            }
          />
        </dl>
      </section>

      <section className="bg-white rounded-xl border p-6">
        <h3 className="font-semibold mb-4">العميل</h3>
        <dl>
          <InfoRow
            label="الاسم"
            value={`${report.customerName} (#${report.customerId})`}
          />
        </dl>
      </section>

      <section className="bg-white rounded-xl border p-6">
        <h3 className="font-semibold mb-4">محتوى البلاغ</h3>
        <dl>
          <InfoRow label="السبب" value={report.reason} />
          <InfoRow label="التفاصيل" value={report.description?.trim() || '—'} />
        </dl>
      </section>

      {isTerminal && (
        <section className="bg-white rounded-xl border p-6">
          <h3 className="font-semibold mb-4">قرار الإدارة</h3>
          <dl>
            <InfoRow label="ملاحظات الإدارة" value={report.adminResolutionNotes ?? '—'} />
            <InfoRow label="بواسطة" value={report.resolvedByAdminName ?? '—'} />
            <InfoRow
              label="تاريخ القرار"
              value={report.resolvedAt ? formatDateTime(report.resolvedAt) : '—'}
            />
          </dl>
        </section>
      )}

      <div className="flex gap-2">
        <Button type="button" variant="outline" onClick={() => navigate(ROUTES.BOOKING_REPORTS)}>
          العودة للقائمة
        </Button>
        <Button type="button" variant="outline" onClick={() => navigate(`${ROUTES.BOOKINGS}/${report.bookingId}`)}>
          عرض الحجز
        </Button>
      </div>

      <UpdateBookingReportStatusModal
        report={report}
        isOpen={statusModalOpen}
        onClose={() => setStatusModalOpen(false)}
        onSubmit={handleUpdateStatus}
        isLoading={updateMutation.isPending}
      />
    </div>
  );
}
