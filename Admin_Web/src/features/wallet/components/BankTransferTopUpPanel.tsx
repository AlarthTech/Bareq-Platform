import { useState } from 'react';
import { Check, X, Eye } from 'lucide-react';
import { formatDateTime, formatLyd } from '../../../core/utils';
import { getErrorMessage } from '../../../core/utils/getErrorMessage';
import { DataTable } from '../../../shared/tables/DataTable';
import { FormModal } from '../../../shared/forms/FormModal';
import { Button } from '../../../shared/ui/Button';
import { useToast } from '../../../shared/context/ToastContext';
import {
  useBankTransferTopUps,
  useBankTransferActions,
  useBankTransferDetail,
} from '../hooks/useWalletTopUps';
import { WalletTopUpStatusBadge } from '../components/WalletTopUpStatusBadge';
import type { BankTransferTopUpDTO, WalletTopUpStatus } from '../types';

const STATUS_TABS: { value: WalletTopUpStatus | ''; label: string }[] = [
  { value: '', label: 'الكل' },
  { value: 'Pending', label: 'قيد الانتظار' },
  { value: 'Completed', label: 'مكتمل' },
  { value: 'Rejected', label: 'مرفوض' },
];

export function BankTransferTopUpPanel() {
  const { showToast } = useToast();
  const [statusFilter, setStatusFilter] = useState<WalletTopUpStatus | ''>('Pending');

  const [detailId, setDetailId] = useState<number | null>(null);
  const [approveTarget, setApproveTarget] = useState<BankTransferTopUpDTO | null>(null);
  const [rejectTarget, setRejectTarget] = useState<BankTransferTopUpDTO | null>(null);
  const [approvedAmount, setApprovedAmount] = useState('');
  const [adminNotes, setAdminNotes] = useState('');
  const [rejectReason, setRejectReason] = useState('');

  const { data: items = [], isLoading } = useBankTransferTopUps(statusFilter);
  const { data: detail } = useBankTransferDetail(detailId);
  const { approve, reject } = useBankTransferActions();

  const openApprove = (item: BankTransferTopUpDTO) => {
    setApproveTarget(item);
    setApprovedAmount(String(item.requestedAmount));
    setAdminNotes('');
  };

  const handleApprove = async () => {
    if (!approveTarget) return;
    const amount = Number.parseFloat(approvedAmount);
    if (Number.isNaN(amount) || amount < 0) {
      showToast('مبلغ الموافقة غير صالح', 'error');
      return;
    }
    try {
      await approve.mutateAsync({
        id: approveTarget.id,
        payload: {
          approvedAmount: amount,
          adminNotes: adminNotes.trim() || undefined,
        },
      });
      showToast('تمت الموافقة وشحن المحفظة', 'success');
      setApproveTarget(null);
      setDetailId(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const handleReject = async () => {
    if (!rejectTarget || !rejectReason.trim()) {
      showToast('سبب الرفض مطلوب', 'error');
      return;
    }
    try {
      await reject.mutateAsync({
        id: rejectTarget.id,
        payload: { reason: rejectReason.trim() },
      });
      showToast('تم رفض طلب التحويل', 'success');
      setRejectTarget(null);
      setRejectReason('');
      setDetailId(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const displayDetail = detail ?? items.find((i) => i.id === detailId);

  return (
    <>
      <div className="flex flex-wrap gap-2 mb-4">
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.value || 'all'}
            type="button"
            onClick={() => setStatusFilter(tab.value)}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              statusFilter === tab.value
                ? 'bg-bareq-600 text-white'
                : 'bg-white border text-gray-700 hover:bg-gray-50'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <DataTable<BankTransferTopUpDTO>
        isLoading={isLoading}
        data={items}
        emptyMessage="لا توجد طلبات تحويل بنكي"
        columns={[
          { key: 'id', header: '#', render: (t) => `#${t.id}` },
          {
            key: 'customer',
            header: 'العميل',
            render: (t) => t.customerName ?? (t.customerId ? `#${t.customerId}` : '—'),
          },
          {
            key: 'requestedAmount',
            header: 'المبلغ المطلوب',
            render: (t) => formatLyd(t.requestedAmount),
          },
          {
            key: 'status',
            header: 'الحالة',
            render: (t) => <WalletTopUpStatusBadge status={t.status} />,
          },
          { key: 'createdAt', header: 'التاريخ', render: (t) => formatDateTime(t.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (t) => (
              <div className="flex gap-2 justify-end">
                <button
                  type="button"
                  onClick={() => setDetailId(t.id)}
                  className="text-sm text-gray-600 hover:text-bareq-600"
                >
                  <Eye className="w-4 h-4 inline" />
                </button>
                {t.status === 'Pending' && (
                  <>
                    <button
                      type="button"
                      onClick={() => openApprove(t)}
                      className="text-sm text-green-600 hover:underline"
                    >
                      <Check className="w-4 h-4 inline" /> موافقة
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setRejectTarget(t);
                        setRejectReason('');
                      }}
                      className="text-sm text-red-600 hover:underline"
                    >
                      <X className="w-4 h-4 inline" /> رفض
                    </button>
                  </>
                )}
              </div>
            ),
          },
        ]}
      />

      {displayDetail && detailId != null && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4"
          onClick={() => setDetailId(null)}
        >
          <div
            className="bg-white rounded-xl max-w-md w-full p-6 text-right"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="font-bold mb-4">طلب تحويل #{displayDetail.id}</h3>
            <dl className="space-y-2 text-sm">
              <div className="flex justify-between">
                <dt className="text-gray-500">المبلغ المطلوب</dt>
                <dd>{formatLyd(displayDetail.requestedAmount)}</dd>
              </div>
              {displayDetail.approvedAmount != null && (
                <div className="flex justify-between">
                  <dt className="text-gray-500">المبلغ المعتمد</dt>
                  <dd>{formatLyd(displayDetail.approvedAmount)}</dd>
                </div>
              )}
              <div className="flex justify-between">
                <dt className="text-gray-500">الحالة</dt>
                <dd>
                  <WalletTopUpStatusBadge status={displayDetail.status} />
                </dd>
              </div>
              {displayDetail.notes && (
                <div>
                  <dt className="text-gray-500">ملاحظات العميل</dt>
                  <dd className="mt-1">{displayDetail.notes}</dd>
                </div>
              )}
              {displayDetail.adminNotes && (
                <div>
                  <dt className="text-gray-500">ملاحظات المشرف</dt>
                  <dd className="mt-1">{displayDetail.adminNotes}</dd>
                </div>
              )}
            </dl>
            {displayDetail.status === 'Pending' && (
              <div className="flex gap-2 mt-4">
                <Button type="button" className="flex-1" onClick={() => openApprove(displayDetail)}>
                  موافقة
                </Button>
                <Button
                  type="button"
                  variant="danger"
                  className="flex-1"
                  onClick={() => {
                    setRejectTarget(displayDetail);
                    setRejectReason('');
                  }}
                >
                  رفض
                </Button>
              </div>
            )}
          </div>
        </div>
      )}

      <FormModal
        isOpen={approveTarget != null}
        onClose={() => setApproveTarget(null)}
        title="اعتماد التحويل البنكي"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setApproveTarget(null)}>
              إلغاء
            </Button>
            <Button type="button" disabled={approve.isPending} onClick={() => void handleApprove()}>
              اعتماد وشحن المحفظة
            </Button>
          </>
        }
      >
        <p className="text-sm text-gray-600 mb-3">
          المبلغ المطلوب: {approveTarget ? formatLyd(approveTarget.requestedAmount) : '—'}
        </p>
        <label className="text-xs text-gray-500 block mb-1">مبلغ الموافقة (د.ل)</label>
        <input
          type="number"
          min={0}
          step={0.01}
          value={approvedAmount}
          onChange={(e) => setApprovedAmount(e.target.value)}
          className="w-full border rounded-lg px-3 py-2 mb-3"
        />
        <label className="text-xs text-gray-500 block mb-1">ملاحظات المشرف (اختياري)</label>
        <textarea
          value={adminNotes}
          onChange={(e) => setAdminNotes(e.target.value)}
          className="w-full border rounded-lg px-3 py-2 min-h-[80px]"
        />
      </FormModal>

      <FormModal
        isOpen={rejectTarget != null}
        onClose={() => setRejectTarget(null)}
        title="رفض طلب التحويل"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setRejectTarget(null)}>
              إلغاء
            </Button>
            <Button
              type="button"
              variant="danger"
              disabled={reject.isPending || !rejectReason.trim()}
              onClick={() => void handleReject()}
            >
              رفض
            </Button>
          </>
        }
      >
        <textarea
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
          placeholder="سبب الرفض (مطلوب)"
          className="w-full border rounded-lg px-3 py-2 min-h-[100px]"
        />
      </FormModal>
    </>
  );
}
