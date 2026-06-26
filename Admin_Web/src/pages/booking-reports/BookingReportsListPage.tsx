import { useMemo, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Eye, Pencil, RotateCcw } from 'lucide-react';
import {
  useBookingReports,
  useUpdateBookingReportStatus,
} from '../../hooks/useBookingReports';
import { formatDateTime } from '../../core/utils';
import { getErrorMessage } from '../../core/utils/getErrorMessage';
import { ROUTES, PAGINATION } from '../../core/constants';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { BookingReportStatusBadge } from '../../shared/components/BookingReportStatusBadge';
import { useToast } from '../../shared/context/ToastContext';
import { UpdateBookingReportStatusModal } from '../../features/booking-reports/components/UpdateBookingReportStatusModal';
import {
  BookingReportStatus,
  BOOKING_REPORT_STATUS_LABELS,
  type BookingReport,
  type BookingReportFilters,
  type BookingReportStatusValue,
} from '../../types/booking-report';

function truncate(text: string, max = 60) {
  return text.length <= max ? text : `${text.slice(0, max)}…`;
}

function parseOptionalInt(value: string): number | undefined {
  const n = Number.parseInt(value, 10);
  return Number.isNaN(n) ? undefined : n;
}

export default function BookingReportsListPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { showToast } = useToast();

  const initialStatus = searchParams.get('status');
  const initialBookingId = searchParams.get('bookingId');

  const [status, setStatus] = useState(initialStatus ?? '');
  const [bookingId, setBookingId] = useState(initialBookingId ?? '');
  const [customerId, setCustomerId] = useState('');
  const [companyId, setCompanyId] = useState('');
  const [workerId, setWorkerId] = useState('');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [page, setPage] = useState<number>(PAGINATION.DEFAULT_PAGE);
  const [pageSize, setPageSize] = useState<number>(PAGINATION.DEFAULT_PAGE_SIZE);

  const [editReport, setEditReport] = useState<BookingReport | null>(null);

  const filters: BookingReportFilters = useMemo(
    () => ({
      page,
      pageSize,
      ...(status !== '' && { status: Number(status) as BookingReportFilters['status'] }),
      ...(bookingId.trim() && { bookingId: parseOptionalInt(bookingId.trim()) }),
      ...(customerId.trim() && { customerId: parseOptionalInt(customerId.trim()) }),
      ...(companyId.trim() && { companyId: parseOptionalInt(companyId.trim()) }),
      ...(workerId.trim() && { workerId: parseOptionalInt(workerId.trim()) }),
      ...(fromDate && { fromDate }),
      ...(toDate && { toDate }),
    }),
    [page, pageSize, status, bookingId, customerId, companyId, workerId, fromDate, toDate]
  );

  const { data, isLoading } = useBookingReports(filters);
  const updateMutation = useUpdateBookingReportStatus();

  const resetFilters = () => {
    setStatus('');
    setBookingId('');
    setCustomerId('');
    setCompanyId('');
    setWorkerId('');
    setFromDate('');
    setToDate('');
    setPage(1);
  };

  const handleUpdateStatus = async (payload: {
    status: 1 | 2 | 3;
    adminResolutionNotes?: string;
  }) => {
    if (!editReport) return;
    try {
      await updateMutation.mutateAsync({ id: editReport.id, ...payload });
      showToast('تم تحديث حالة البلاغ', 'success');
      setEditReport(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  return (
    <div>
      <PageHeader
        title="بلاغات الحجوزات"
        subtitle="شكاوى العملاء المرتبطة بحجوزات محددة — منفصلة عن بلاغات العاملات والشركات"
      />

      <div className="bg-white rounded-xl border p-4 mb-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          <div>
            <label className="text-xs text-gray-500 block mb-1">الحالة</label>
            <select
              value={status}
              onChange={(e) => {
                setStatus(e.target.value);
                setPage(1);
              }}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
            >
              <option value="">الكل</option>
              {Object.entries(BookingReportStatus)
                .filter((entry): entry is [string, BookingReportStatusValue] => typeof entry[1] === 'number')
                .map(([, statusValue]) => (
                  <option key={statusValue} value={statusValue}>
                    {BOOKING_REPORT_STATUS_LABELS[statusValue]}
                  </option>
                ))}
            </select>
          </div>
          <div>
            <label className="text-xs text-gray-500 block mb-1">رقم الحجز</label>
            <input
              type="number"
              min={1}
              value={bookingId}
              onChange={(e) => {
                setBookingId(e.target.value);
                setPage(1);
              }}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs text-gray-500 block mb-1">معرف العميل</label>
            <input
              type="number"
              min={1}
              value={customerId}
              onChange={(e) => {
                setCustomerId(e.target.value);
                setPage(1);
              }}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs text-gray-500 block mb-1">معرف الشركة</label>
            <input
              type="number"
              min={1}
              value={companyId}
              onChange={(e) => {
                setCompanyId(e.target.value);
                setPage(1);
              }}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs text-gray-500 block mb-1">معرف العاملة</label>
            <input
              type="number"
              min={1}
              value={workerId}
              onChange={(e) => {
                setWorkerId(e.target.value);
                setPage(1);
              }}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs text-gray-500 block mb-1">من تاريخ</label>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => {
                setFromDate(e.target.value);
                setPage(1);
              }}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="text-xs text-gray-500 block mb-1">إلى تاريخ</label>
            <input
              type="date"
              value={toDate}
              onChange={(e) => {
                setToDate(e.target.value);
                setPage(1);
              }}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
            />
          </div>
          <div className="flex items-end">
            <button
              type="button"
              onClick={resetFilters}
              className="inline-flex items-center gap-2 px-3 py-2 text-sm border rounded-lg hover:bg-gray-50"
            >
              <RotateCcw className="w-4 h-4" />
              إعادة تعيين
            </button>
          </div>
        </div>
      </div>

      <DataTable<BookingReport>
        isLoading={isLoading}
        data={data?.items ?? []}
        paged={data}
        emptyMessage="لا توجد بلاغات حجوزات"
        onPageChange={setPage}
        onPageSizeChange={(size) => {
          setPageSize(size);
          setPage(1);
        }}
        columns={[
          { key: 'id', header: '#', render: (r) => `#${r.id}` },
          {
            key: 'bookingId',
            header: 'الحجز',
            render: (r) => (
              <Link
                to={`${ROUTES.BOOKINGS}/${r.bookingId}`}
                className="text-bareq-600 hover:underline font-medium"
              >
                #{r.bookingId}
              </Link>
            ),
          },
          {
            key: 'bookingStatusName',
            header: 'حالة الحجز',
            render: (r) => (
              <span className="inline-flex px-2 py-0.5 rounded-full text-xs bg-gray-100 text-gray-800">
                {r.bookingStatusName}
              </span>
            ),
          },
          { key: 'customerName', header: 'العميل' },
          { key: 'companyName', header: 'الشركة' },
          {
            key: 'workerName',
            header: 'العاملة',
            render: (r) => r.workerName ?? '—',
          },
          {
            key: 'reason',
            header: 'السبب',
            render: (r) => (
              <span title={r.reason} className="max-w-xs inline-block truncate">
                {truncate(r.reason)}
              </span>
            ),
          },
          {
            key: 'status',
            header: 'حالة البلاغ',
            render: (r) => (
              <BookingReportStatusBadge status={r.status} label={r.statusName} />
            ),
          },
          {
            key: 'createdAt',
            header: 'التاريخ',
            render: (r) => formatDateTime(r.createdAt),
          },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (r) => (
              <div className="flex gap-1 justify-end">
                <button
                  type="button"
                  onClick={() => navigate(`${ROUTES.BOOKING_REPORTS}/${r.id}`)}
                  className="p-1.5 text-gray-600 hover:bg-gray-100 rounded"
                  title="عرض"
                >
                  <Eye className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setEditReport(r)}
                  className="p-1.5 text-blue-600 hover:bg-blue-50 rounded"
                  title="تحديث الحالة"
                >
                  <Pencil className="w-4 h-4" />
                </button>
              </div>
            ),
          },
        ]}
      />

      <UpdateBookingReportStatusModal
        report={editReport}
        isOpen={editReport != null}
        onClose={() => setEditReport(null)}
        onSubmit={handleUpdateStatus}
        isLoading={updateMutation.isPending}
      />
    </div>
  );
}
