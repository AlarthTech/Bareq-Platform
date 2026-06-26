import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Trash2 } from 'lucide-react';
import { reviewsApi } from '../../api/reviews.api';
import { usePagination } from '../../core/hooks/usePagination';
import { formatDateTime } from '../../core/utils';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { useToast } from '../../shared/context/ToastContext';
import type { Review } from '../../types/api.types';

export default function ReviewsPage() {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['reviews', page, pageSize],
    queryFn: () => reviewsApi.getAll({ page, pageSize }),
  });

  const deleteMut = useMutation({
    mutationFn: reviewsApi.delete,
    onSuccess: () => {
      showToast('تم حذف التقييم', 'success');
      qc.invalidateQueries({ queryKey: ['reviews'] });
      setDeleteId(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div>
      <PageHeader title="التقييمات" subtitle="تقييمات العملاء للعاملات" />
      <DataTable<Review>
        isLoading={isLoading}
        data={data?.items ?? []}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'bookingId', header: 'الحجز', render: (r) => `#${r.bookingId}` },
          { key: 'userName', header: 'العميل', render: (r) => r.userName ?? `#${r.userId}` },
          { key: 'workerName', header: 'العاملة', render: (r) => r.workerName ?? `#${r.workerId}` },
          {
            key: 'rating',
            header: 'التقييم',
            render: (r) => (
              <span className="text-yellow-600 font-medium">{'★'.repeat(r.rating)}{'☆'.repeat(5 - r.rating)}</span>
            ),
          },
          { key: 'comment', header: 'التعليق', render: (r) => r.comment ?? '—' },
          { key: 'createdAt', header: 'التاريخ', render: (r) => formatDateTime(r.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (r) => (
              <button type="button" onClick={() => setDeleteId(r.id)} className="text-red-600 p-1">
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
        title="حذف التقييم"
        message="هل أنت متأكد؟"
        isLoading={deleteMut.isPending}
      />
    </div>
  );
}
