import { useState } from 'react';
import { Check, X } from 'lucide-react';
import { formatDateTime, formatLyd } from '../../../core/utils';
import { getErrorMessage } from '../../../core/utils/getErrorMessage';
import { DataTable } from '../../../shared/tables/DataTable';
import { ConfirmModal } from '../../../shared/components/ConfirmModal';
import { useToast } from '../../../shared/context/ToastContext';
import { useBankCardTopUps, useBankCardActions } from '../hooks/useWalletTopUps';
import { WalletTopUpStatusBadge } from '../components/WalletTopUpStatusBadge';
import type { BankCardTopUpDTO, WalletTopUpStatus } from '../types';

const STATUS_TABS: { value: WalletTopUpStatus | ''; label: string }[] = [
  { value: '', label: 'الكل' },
  { value: 'Pending', label: 'قيد الانتظار' },
  { value: 'Completed', label: 'مكتمل' },
  { value: 'Failed', label: 'فشل' },
];

export function BankCardTopUpPanel() {
  const { showToast } = useToast();
  const [statusFilter, setStatusFilter] = useState<WalletTopUpStatus | ''>('Pending');
  const [confirmId, setConfirmId] = useState<number | null>(null);
  const [failId, setFailId] = useState<number | null>(null);

  const { data: items = [], isLoading } = useBankCardTopUps(statusFilter);
  const { confirm, fail } = useBankCardActions();

  const handleConfirm = async () => {
    if (confirmId == null) return;
    try {
      await confirm.mutateAsync(confirmId);
      showToast('تم تأكيد شحن البطاقة', 'success');
      setConfirmId(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const handleFail = async () => {
    if (failId == null) return;
    try {
      await fail.mutateAsync(failId);
      showToast('تم تسجيل فشل الشحن', 'success');
      setFailId(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  return (
    <>
      <p className="text-sm text-gray-600 bg-blue-50 border border-blue-100 rounded-lg px-4 py-3 mb-4">
        معظم طلبات البطاقة تُؤكَّد تلقائياً عبر بوابة الدفع. استخدم التأكيد اليدوي فقط عند
        الحاجة.
      </p>

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

      <DataTable<BankCardTopUpDTO>
        isLoading={isLoading}
        data={items}
        emptyMessage="لا توجد طلبات شحن بطاقة"
        columns={[
          { key: 'id', header: '#', render: (t) => `#${t.id}` },
          {
            key: 'customer',
            header: 'العميل',
            render: (t) => t.customerName ?? (t.customerId ? `#${t.customerId}` : '—'),
          },
          {
            key: 'requestedAmount',
            header: 'المبلغ',
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
            render: (t) =>
              t.status === 'Pending' ? (
                <div className="flex gap-2 justify-end">
                  <button
                    type="button"
                    onClick={() => setConfirmId(t.id)}
                    className="text-sm text-green-600 hover:underline"
                  >
                    <Check className="w-4 h-4 inline" /> تأكيد
                  </button>
                  <button
                    type="button"
                    onClick={() => setFailId(t.id)}
                    className="text-sm text-red-600 hover:underline"
                  >
                    <X className="w-4 h-4 inline" /> فشل
                  </button>
                </div>
              ) : (
                '—'
              ),
          },
        ]}
      />

      <ConfirmModal
        isOpen={confirmId != null}
        onClose={() => setConfirmId(null)}
        onConfirm={() => void handleConfirm()}
        title="تأكيد شحن البطاقة"
        message="سيتم إضافة الرصيد لمحفظة العميل. هل تريد المتابعة؟"
        confirmText="تأكيد"
        isLoading={confirm.isPending}
      />

      <ConfirmModal
        isOpen={failId != null}
        onClose={() => setFailId(null)}
        onConfirm={() => void handleFail()}
        title="تسجيل فشل الشحن"
        message="سيتم وضع الطلب كفاشل. هل أنت متأكد؟"
        confirmText="تسجيل الفشل"
        variant="danger"
        isLoading={fail.isPending}
      />
    </>
  );
}
