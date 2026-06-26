import { useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Eye, Pencil, Trash2, Search } from 'lucide-react';
import { usePagination } from '../../core/hooks/usePagination';
import {
  useReports,
  useUpdateReportStatus,
  useDeleteReport,
} from '../../hooks/useReports';
import { formatDateTime } from '../../core/utils';
import { getErrorMessage } from '../../core/utils/getErrorMessage';
import { ROUTES } from '../../core/constants';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ReportStatusBadge } from '../../shared/components/ReportStatusBadge';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { FormModal } from '../../shared/forms/FormModal';
import { Button } from '../../shared/ui/Button';
import { useToast } from '../../shared/context/ToastContext';
import {
  ReportStatus,
  REPORT_STATUS_LABELS,
  ReportTargetType,
  type Report,
  type ReportStatusValue,
} from '../../types/report.types';

function truncate(text: string, max = 80) {
  return text.length <= max ? text : `${text.slice(0, max)}…`;
}

function getTargetName(report: Report) {
  if (report.targetType === ReportTargetType.Worker) {
    return report.workerName ?? (report.workerId ? `#${report.workerId}` : '—');
  }
  return report.companyName ?? (report.companyId ? `#${report.companyId}` : '—');
}

export default function ReportsListPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const { showToast } = useToast();

  const initialStatus = searchParams.get('status');
  const [statusFilter, setStatusFilter] = useState<string>(initialStatus ?? '');
  const [targetFilter, setTargetFilter] = useState<string>('');
  const [search, setSearch] = useState('');
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [editReport, setEditReport] = useState<Report | null>(null);
  const [newStatus, setNewStatus] = useState<ReportStatusValue>(ReportStatus.Pending);
  const [adminNotes, setAdminNotes] = useState('');

  const { data, isLoading } = useReports(page, pageSize);
  const updateMutation = useUpdateReportStatus();
  const deleteMutation = useDeleteReport();

  const filtered = useMemo(() => {
    let items = data?.items ?? [];
    if (statusFilter !== '') {
      items = items.filter((r) => r.status === Number(statusFilter));
    }
    if (targetFilter !== '') {
      items = items.filter((r) => r.targetType === Number(targetFilter));
    }
    if (search.trim()) {
      const q = search.trim().toLowerCase();
      items = items.filter(
        (r) =>
          r.description.toLowerCase().includes(q) ||
          r.userName?.toLowerCase().includes(q) ||
          r.workerName?.toLowerCase().includes(q) ||
          r.companyName?.toLowerCase().includes(q)
      );
    }
    return items;
  }, [data?.items, statusFilter, targetFilter, search]);

  const openStatusModal = (report: Report) => {
    setEditReport(report);
    setNewStatus(report.status);
    setAdminNotes(report.adminNotes ?? '');
  };

  const submitStatus = async () => {
    if (!editReport) return;
    try {
      await updateMutation.mutateAsync({
        id: editReport.id,
        status: newStatus,
        adminNotes: adminNotes.trim() || undefined,
      });
      showToast('تم تحديث حالة البلاغ', 'success');
      setEditReport(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    try {
      await deleteMutation.mutateAsync(deleteId);
      showToast('تم حذف البلاغ', 'success');
      setDeleteId(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  return (
    <div>
      <PageHeader title="البلاغات" subtitle="بلاغات العملاء ضد العاملات والشركات" />

      <DataTable<Report>
        isLoading={isLoading}
        data={filtered}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        toolbar={
          <div className="flex flex-wrap gap-3">
            <div className="relative flex-1 min-w-[200px] max-w-sm">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="search"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="بحث في الوصف أو المُبلِّغ..."
                className="w-full pr-10 pl-3 py-2 border border-gray-200 rounded-lg text-sm"
              />
            </div>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm"
            >
              <option value="">الكل — الحالة</option>
              {Object.entries(REPORT_STATUS_LABELS).map(([value, label]) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
            <select
              value={targetFilter}
              onChange={(e) => setTargetFilter(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm"
            >
              <option value="">الكل — النوع</option>
              <option value={ReportTargetType.Worker}>عاملة</option>
              <option value={ReportTargetType.Company}>شركة</option>
            </select>
          </div>
        }
        columns={[
          { key: 'id', header: '#' },
          { key: 'userName', header: 'المُبلِّغ', render: (r) => r.userName ?? `#${r.userId}` },
          { key: 'targetTypeName', header: 'النوع' },
          { key: 'target', header: 'الهدف', render: (r) => getTargetName(r) },
          {
            key: 'description',
            header: 'الوصف',
            render: (r) => (
              <span title={r.description} className="max-w-xs inline-block truncate">
                {truncate(r.description)}
              </span>
            ),
          },
          {
            key: 'status',
            header: 'الحالة',
            render: (r) => <ReportStatusBadge status={r.status} label={r.statusName} />,
          },
          { key: 'createdAt', header: 'التاريخ', render: (r) => formatDateTime(r.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (r) => (
              <div className="flex gap-1 justify-end">
                <button
                  type="button"
                  onClick={() => navigate(`${ROUTES.REPORTS}/${r.id}`)}
                  className="p-1.5 text-gray-600 hover:bg-gray-100 rounded"
                  title="عرض"
                >
                  <Eye className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => openStatusModal(r)}
                  className="p-1.5 text-blue-600 hover:bg-blue-50 rounded"
                  title="تحديث الحالة"
                >
                  <Pencil className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setDeleteId(r.id)}
                  className="p-1.5 text-red-600 hover:bg-red-50 rounded"
                  title="حذف"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ),
          },
        ]}
      />

      <FormModal
        isOpen={editReport !== null}
        onClose={() => setEditReport(null)}
        title="تحديث حالة البلاغ"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setEditReport(null)}>إلغاء</Button>
            <Button
              type="button"
              onClick={submitStatus}
              disabled={updateMutation.isPending}
              className="!bg-bareq-600 hover:!bg-bareq-700"
            >
              {updateMutation.isPending ? 'جاري الحفظ...' : 'حفظ'}
            </Button>
          </>
        }
      >
        <div className="space-y-4 text-right">
          <div>
            <label className="block text-sm font-medium mb-1">الحالة</label>
            <select
              value={newStatus}
              onChange={(e) => setNewStatus(Number(e.target.value) as ReportStatusValue)}
              className="w-full border rounded-lg px-3 py-2"
            >
              {Object.entries(REPORT_STATUS_LABELS).map(([value, label]) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">ملاحظات الإدارة</label>
            <textarea
              value={adminNotes}
              onChange={(e) => setAdminNotes(e.target.value)}
              maxLength={2000}
              rows={4}
              placeholder="ملاحظات داخلية — لا يراها العميل"
              className="w-full border rounded-lg px-3 py-2 text-sm"
            />
          </div>
        </div>
      </FormModal>

      <ConfirmModal
        isOpen={deleteId !== null}
        onClose={() => setDeleteId(null)}
        onConfirm={handleDelete}
        title="حذف البلاغ"
        message="هل أنت متأكد من حذف هذا البلاغ؟"
        confirmText="حذف"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
