import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Trash2 } from 'lucide-react';
import { workTypesApi } from '../../api/workTypes.api';
import { usePagination } from '../../core/hooks/usePagination';
import { formatDate, formatCurrency } from '../../core/utils';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { useToast } from '../../shared/context/ToastContext';
import type { WorkType } from '../../types/api.types';

export default function WorkTypesPage() {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['work-types', page, pageSize],
    queryFn: () => workTypesApi.getAll({ page, pageSize }),
  });

  const deleteMut = useMutation({
    mutationFn: workTypesApi.delete,
    onSuccess: () => {
      showToast('تم الحذف', 'success');
      qc.invalidateQueries({ queryKey: ['work-types'] });
      setDeleteId(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div>
      <PageHeader title="أنواع العمل" subtitle="ورديات وعقود الشركات" />
      <DataTable<WorkType>
        isLoading={isLoading}
        data={data?.items ?? []}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'name', header: 'الاسم' },
          { key: 'companyName', header: 'الشركة', render: (w) => w.companyName ?? `#${w.companyId}` },
          {
            key: 'schedule',
            header: 'الوقت',
            render: (w) => (w.isMonthly ? 'عقد شهري' : `${w.startTime} – ${w.endTime}`),
          },
          {
            key: 'price',
            header: 'السعر',
            render: (w) =>
              w.isMonthly && w.monthlyPrice
                ? formatCurrency(w.monthlyPrice)
                : formatCurrency(w.price),
          },
          { key: 'isOvernight', header: 'ليلي', render: (w) => (w.isOvernight ? 'نعم' : 'لا') },
          { key: 'isActive', header: 'نشط', render: (w) => (w.isActive ? 'نعم' : 'لا') },
          { key: 'createdAt', header: 'تاريخ الإنشاء', render: (w) => formatDate(w.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (w) => (
              <button type="button" onClick={() => setDeleteId(w.id)} className="text-red-600 p-1">
                <Trash2 className="w-4 h-4" />
              </button>
            ),
          },
        ]}
      />
      <ConfirmModal
        isOpen={deleteId !== null}
        onClose={() => setDeleteId(null)}
        onConfirm={() => deleteId && deleteMut.mutate(deleteId)}
        title="حذف نوع العمل"
        message="هل أنت متأكد؟"
        isLoading={deleteMut.isPending}
      />
    </div>
  );
}
