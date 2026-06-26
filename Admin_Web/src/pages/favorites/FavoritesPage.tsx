import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Trash2 } from 'lucide-react';
import { favoritesApi } from '../../api/favorites.api';
import { usePagination } from '../../core/hooks/usePagination';
import { formatDateTime } from '../../core/utils';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { useToast } from '../../shared/context/ToastContext';
import type { Favorite } from '../../types/api.types';

export default function FavoritesPage() {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['favorites', page, pageSize],
    queryFn: () => favoritesApi.getAll({ page, pageSize }),
  });

  const deleteMut = useMutation({
    mutationFn: favoritesApi.delete,
    onSuccess: () => {
      showToast('تم الحذف', 'success');
      qc.invalidateQueries({ queryKey: ['favorites'] });
      setDeleteId(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div>
      <PageHeader title="المفضلة" subtitle="عاملات مفضلة لدى العملاء (عرض فقط)" />
      <DataTable<Favorite>
        isLoading={isLoading}
        data={data?.items ?? []}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'userName', header: 'العميل', render: (f) => f.userName ?? `#${f.userId}` },
          { key: 'workerName', header: 'العاملة', render: (f) => f.workerName ?? `#${f.workerId}` },
          { key: 'companyName', header: 'الشركة', render: (f) => f.companyName ?? `#${f.companyId}` },
          { key: 'createdAt', header: 'تاريخ الإضافة', render: (f) => formatDateTime(f.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (f) => (
              <button type="button" onClick={() => setDeleteId(f.id)} className="text-red-600 p-1">
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
        title="حذف من المفضلة"
        message="هل أنت متأكد؟"
        isLoading={deleteMut.isPending}
      />
    </div>
  );
}
