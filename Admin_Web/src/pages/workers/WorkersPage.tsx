import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Power, Trash2 } from 'lucide-react';
import { workersApi } from '../../api/workers.api';
import { usePagination } from '../../core/hooks/usePagination';
import { formatDate, buildFileUrl } from '../../core/utils';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { useToast } from '../../shared/context/ToastContext';
import type { Worker } from '../../types/api.types';

export default function WorkersPage() {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['workers', page, pageSize],
    queryFn: () => workersApi.getAll({ page, pageSize }),
  });

  const toggleActive = useMutation({
    mutationFn: workersApi.toggleActive,
    onSuccess: (r) => {
      showToast(r.message, 'success');
      qc.invalidateQueries({ queryKey: ['workers'] });
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const toggleAvailable = useMutation({
    mutationFn: workersApi.toggleAvailable,
    onSuccess: (r) => {
      showToast(r.message, 'success');
      qc.invalidateQueries({ queryKey: ['workers'] });
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const deleteMut = useMutation({
    mutationFn: workersApi.delete,
    onSuccess: () => {
      showToast('تم حذف العاملة', 'success');
      qc.invalidateQueries({ queryKey: ['workers'] });
      setDeleteId(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div>
      <PageHeader title="العاملات" subtitle="إدارة عاملات الشركات" />
      <DataTable<Worker>
        isLoading={isLoading}
        data={data?.items ?? []}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'fullName', header: 'الاسم' },
          { key: 'companyName', header: 'الشركة', render: (w) => w.companyName ?? `#${w.companyId}` },
          { key: 'nationalityName', header: 'الجنسية', render: (w) => w.nationalityName ?? '—' },
          { key: 'age', header: 'العمر' },
          { key: 'experienceYears', header: 'الخبرة (سنوات)' },
          {
            key: 'isAvailable',
            header: 'متاحة',
            render: (w) => (w.isAvailable ? 'نعم' : 'لا'),
          },
          {
            key: 'isActive',
            header: 'نشطة',
            render: (w) => (w.isActive ? 'نعم' : 'لا'),
          },
          {
            key: 'healthCertificateURL',
            header: 'الشهادة الصحية',
            render: (w) => {
              const url = buildFileUrl(w.healthCertificateURL);
              return url ? (
                <a href={url} target="_blank" rel="noopener noreferrer" className="text-bareq-600 text-sm">عرض</a>
              ) : '—';
            },
          },
          { key: 'createdAt', header: 'تاريخ الإضافة', render: (w) => formatDate(w.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (w) => (
              <div className="flex gap-1 justify-end">
                <button type="button" onClick={() => toggleActive.mutate(w.id)} className="p-1.5 text-blue-600 hover:bg-blue-50 rounded" title="تفعيل/تعطيل">
                  <Power className="w-4 h-4" />
                </button>
                <button type="button" onClick={() => toggleAvailable.mutate(w.id)} className="text-xs text-purple-600 px-2 py-1 hover:bg-purple-50 rounded">
                  توفر
                </button>
                <button type="button" onClick={() => setDeleteId(w.id)} className="p-1.5 text-red-600 hover:bg-red-50 rounded">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ),
          },
        ]}
      />
      <ConfirmModal
        isOpen={deleteId !== null}
        onClose={() => setDeleteId(null)}
        onConfirm={() => deleteId && deleteMut.mutate(deleteId)}
        title="حذف العاملة"
        message="هل أنت متأكد؟ هذا حذف نهائي."
        isLoading={deleteMut.isPending}
      />
    </div>
  );
}
