import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2 } from 'lucide-react';
import { referenceApi } from '../../api/reference.api';
import { usePagination } from '../../core/hooks/usePagination';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { useToast } from '../../shared/context/ToastContext';
import type { CleaningService } from '../../types/api.types';

export default function CleaningServicesPage() {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [name, setName] = useState('');
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['cleaning-services', page, pageSize],
    queryFn: () => referenceApi.getCleaningServices({ page, pageSize }),
  });

  const createMut = useMutation({
    mutationFn: () => referenceApi.createCleaningService({ name }),
    onSuccess: () => {
      showToast('تمت الإضافة', 'success');
      setName('');
      qc.invalidateQueries({ queryKey: ['cleaning-services'] });
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const deleteMut = useMutation({
    mutationFn: referenceApi.deleteCleaningService,
    onSuccess: () => {
      showToast('تم الحذف', 'success');
      qc.invalidateQueries({ queryKey: ['cleaning-services'] });
      setDeleteId(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div>
      <PageHeader title="خدمات التنظيف" subtitle="البيانات المرجعية — خدمات التنظيف" />
      <div className="flex gap-2 mb-4">
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="اسم الخدمة" className="border rounded-lg px-3 py-2 flex-1 max-w-xs" />
        <button type="button" onClick={() => name && createMut.mutate()} className="inline-flex items-center gap-1 px-4 py-2 bg-bareq-600 text-white rounded-lg">
          <Plus className="w-4 h-4" /> إضافة
        </button>
      </div>
      <DataTable<CleaningService>
        isLoading={isLoading}
        data={data?.items ?? []}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'name', header: 'الاسم' },
          { key: 'description', header: 'الوصف', render: (s) => s.description ?? '—' },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (s) => (
              <button type="button" onClick={() => setDeleteId(s.id)} className="text-red-600"><Trash2 className="w-4 h-4" /></button>
            ),
          },
        ]}
      />
      <ConfirmModal isOpen={deleteId !== null} onClose={() => setDeleteId(null)} onConfirm={() => deleteId && deleteMut.mutate(deleteId)} title="حذف الخدمة" message="تأكيد؟" isLoading={deleteMut.isPending} />
    </div>
  );
}
