import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowRight, Trash2 } from 'lucide-react';
import {
  useReport,
  useUpdateReportStatus,
  useDeleteReport,
} from '../../hooks/useReports';
import { formatDateTime } from '../../core/utils';
import { getErrorMessage } from '../../core/utils/getErrorMessage';
import { ROUTES } from '../../core/constants';
import { PageHeader } from '../../shared/components/PageHeader';
import { ReportStatusBadge } from '../../shared/components/ReportStatusBadge';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { FormModal } from '../../shared/forms/FormModal';
import { Button } from '../../shared/ui/Button';
import { Loader } from '../../shared/components/Loader';
import { useToast } from '../../shared/context/ToastContext';
import {
  ReportStatus,
  REPORT_STATUS_LABELS,
  ReportTargetType,
  type ReportStatusValue,
} from '../../types/report.types';

export default function ReportDetailPage() {
  const { id } = useParams<{ id: string }>();
  const reportId = Number(id);
  const navigate = useNavigate();
  const { showToast } = useToast();

  const { data: report, isLoading, isError } = useReport(reportId);
  const updateMutation = useUpdateReportStatus();
  const deleteMutation = useDeleteReport();

  const [statusModalOpen, setStatusModalOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [newStatus, setNewStatus] = useState<ReportStatusValue>(ReportStatus.Pending);
  const [adminNotes, setAdminNotes] = useState('');

  if (isLoading) return <Loader />;

  if (isError || !report) {
    return (
      <div className="text-center py-16">
        <p className="text-gray-600 mb-4">البلاغ غير موجود</p>
        <Link to={ROUTES.REPORTS} className="text-bareq-600 hover:underline">
          العودة إلى البلاغات
        </Link>
      </div>
    );
  }

  const targetLabel =
    report.targetType === ReportTargetType.Worker
      ? report.workerName ?? `#${report.workerId}`
      : report.companyName ?? `#${report.companyId}`;

  const openStatusModal = () => {
    setNewStatus(report.status);
    setAdminNotes(report.adminNotes ?? '');
    setStatusModalOpen(true);
  };

  const submitStatus = async () => {
    try {
      await updateMutation.mutateAsync({
        id: report.id,
        status: newStatus,
        adminNotes: adminNotes.trim() || undefined,
      });
      showToast('تم تحديث حالة البلاغ', 'success');
      setStatusModalOpen(false);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(report.id);
      showToast('تم حذف البلاغ', 'success');
      navigate(ROUTES.REPORTS);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  return (
    <div className="max-w-3xl">
      <button
        type="button"
        onClick={() => navigate(ROUTES.REPORTS)}
        className="inline-flex items-center gap-1 text-sm text-gray-600 hover:text-bareq-600 mb-4"
      >
        <ArrowRight className="w-4 h-4" />
        العودة إلى البلاغات
      </button>

      <PageHeader
        title={`بلاغ #${report.id}`}
        subtitle={report.targetTypeName}
        actions={
          <div className="flex gap-2">
            <Button type="button" onClick={openStatusModal} className="!bg-bareq-600 hover:!bg-bareq-700">
              تحديث الحالة
            </Button>
            <Button type="button" variant="danger" onClick={() => setDeleteOpen(true)}>
              <Trash2 className="w-4 h-4 ml-1" />
              حذف
            </Button>
          </div>
        }
      />

      <div className="bg-white rounded-xl border border-gray-200 divide-y">
        <dl className="p-6 space-y-4 text-sm">
          <div className="flex justify-between gap-4">
            <dt className="text-gray-500 shrink-0">المُبلِّغ</dt>
            <dd className="font-medium text-left">
              <Link
                to={ROUTES.USERS.CUSTOMERS}
                className="text-bareq-600 hover:underline"
              >
                {report.userName ?? `#${report.userId}`}
              </Link>
            </dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-gray-500 shrink-0">الهدف</dt>
            <dd className="font-medium text-left">
              {targetLabel}
              {report.targetType === ReportTargetType.Worker && report.workerId && (
                <span className="text-gray-400 text-xs mr-1">(#{report.workerId})</span>
              )}
              {report.targetType === ReportTargetType.Company && report.companyId && (
                <span className="text-gray-400 text-xs mr-1">(#{report.companyId})</span>
              )}
            </dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-gray-500 shrink-0">الحالة</dt>
            <dd><ReportStatusBadge status={report.status} label={report.statusName} /></dd>
          </div>
          <div>
            <dt className="text-gray-500 mb-2">الوصف</dt>
            <dd className="bg-gray-50 rounded-lg p-4 leading-relaxed">{report.description}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-gray-500 shrink-0">تاريخ الإنشاء</dt>
            <dd>{formatDateTime(report.createdAt)}</dd>
          </div>
          {report.updatedAt && (
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500 shrink-0">آخر تحديث</dt>
              <dd>{formatDateTime(report.updatedAt)}</dd>
            </div>
          )}
        </dl>

        <div className="p-6">
          <h3 className="font-semibold text-gray-900 mb-2">ملاحظات الإدارة</h3>
          <p className="text-sm text-gray-500 mb-3">داخلية — لا يراها العميل</p>
          {report.adminNotes ? (
            <p className="bg-amber-50 border border-amber-100 rounded-lg p-4 text-sm whitespace-pre-wrap">
              {report.adminNotes}
            </p>
          ) : (
            <p className="text-gray-400 text-sm">لا توجد ملاحظات</p>
          )}
        </div>
      </div>

      <FormModal
        isOpen={statusModalOpen}
        onClose={() => setStatusModalOpen(false)}
        title="تحديث حالة البلاغ"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setStatusModalOpen(false)}>إلغاء</Button>
            <Button
              type="button"
              onClick={submitStatus}
              disabled={updateMutation.isPending}
              className="!bg-bareq-600 hover:!bg-bareq-700"
            >
              حفظ
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
              className="w-full border rounded-lg px-3 py-2 text-sm"
            />
          </div>
        </div>
      </FormModal>

      <ConfirmModal
        isOpen={deleteOpen}
        onClose={() => setDeleteOpen(false)}
        onConfirm={handleDelete}
        title="حذف البلاغ"
        message="هل أنت متأكد من حذف هذا البلاغ؟"
        confirmText="حذف"
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
