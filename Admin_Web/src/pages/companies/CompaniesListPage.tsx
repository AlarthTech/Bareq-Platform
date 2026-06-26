import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Check, X, Power, Trash2, Eye } from 'lucide-react';
import { companiesApi } from '../../api/companies.api';
import { usePagination } from '../../core/hooks/usePagination';
import { useCompaniesWithStatus } from '../../hooks/useCompaniesWithStatus';
import { formatDate } from '../../core/utils';
import { COMPANY_STATUS_LABELS } from '../../core/utils/companyStatus';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { FilePreview } from '../../shared/components/FilePreview';
import { CompanyStatusBadge } from '../../shared/components/CompanyStatusBadge';
import { useToast } from '../../shared/context/ToastContext';
import type { CompanyWithStatus } from '../../hooks/useCompaniesWithStatus';

type Action = 'verify' | 'active' | 'delete';

export default function CompaniesListPage() {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [selected, setSelected] = useState<CompanyWithStatus | null>(null);
  const [action, setAction] = useState<Action | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data, isLoading } = useQuery({
    queryKey: ['companies', page, pageSize],
    queryFn: () => companiesApi.getAll({ page, pageSize }),
  });

  const { companies, isLoading: statusLoading } = useCompaniesWithStatus(data?.items);

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['companies'] });
    qc.invalidateQueries({ queryKey: ['stats'] });
    setAction(null);
    setSelected(null);
  };

  const verifyMut = useMutation({
    mutationFn: (id: number) => companiesApi.toggleVerified(id),
    onSuccess: (r) => {
      showToast(r.message, 'success');
      invalidate();
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const activeMut = useMutation({
    mutationFn: (id: number) => companiesApi.toggleActive(id),
    onSuccess: (r) => {
      showToast(r.message, 'success');
      invalidate();
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => companiesApi.delete(id),
    onSuccess: () => {
      showToast('تم حذف الشركة', 'success');
      invalidate();
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const confirm = () => {
    if (!selected || !action) return;
    if (action === 'verify') verifyMut.mutate(selected.id);
    else if (action === 'active') activeMut.mutate(selected.id);
    else deleteMut.mutate(selected.id);
  };

  return (
    <div>
      <PageHeader title="الشركات" subtitle="جميع الشركات المسجلة" />
      <DataTable<CompanyWithStatus>
        isLoading={isLoading || statusLoading}
        data={companies}
        paged={data}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'name', header: 'اسم الشركة' },
          { key: 'ownerUserName', header: 'المالك', render: (c) => c.ownerUserName ?? '—' },
          { key: 'cityName', header: 'المدينة', render: (c) => c.cityName ?? '—' },
          { key: 'phone', header: 'الهاتف' },
          {
            key: 'displayStatus',
            header: 'الحالة',
            render: (c) => <CompanyStatusBadge status={c.displayStatus} />,
          },
          { key: 'createdAt', header: 'تاريخ الإنشاء', render: (c) => formatDate(c.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (c) => (
              <div className="flex gap-1 justify-end">
                <button type="button" onClick={() => setSelected(c)} className="p-1.5 hover:bg-gray-100 rounded" title="عرض">
                  <Eye className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => { setSelected(c); setAction('verify'); }}
                  className="p-1.5 text-green-600 hover:bg-green-50 rounded"
                  title="تبديل حالة التوثيق"
                >
                  <Check className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => { setSelected(c); setAction('active'); }}
                  className="p-1.5 text-blue-600 hover:bg-blue-50 rounded"
                  title="تبديل حالة التفعيل"
                >
                  <Power className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => { setSelected(c); setAction('delete'); }}
                  className="p-1.5 text-red-600 hover:bg-red-50 rounded"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ),
          },
        ]}
      />

      {selected && !action && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={() => setSelected(null)}>
          <div className="bg-white rounded-xl max-w-lg w-full p-6 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex justify-between items-start mb-4">
              <h3 className="text-lg font-bold">{selected.name}</h3>
              <button type="button" onClick={() => setSelected(null)}><X className="w-5 h-5" /></button>
            </div>
            <div className="mb-4">
              <CompanyStatusBadge status={selected.displayStatus} />
            </div>
            <dl className="space-y-2 text-sm">
              <div><dt className="text-gray-500">المالك</dt><dd>{selected.ownerUserName}</dd></div>
              <div><dt className="text-gray-500">المدينة</dt><dd>{selected.cityName}</dd></div>
              <div><dt className="text-gray-500">السجل التجاري</dt><dd>{selected.commercialRegNo ?? '—'}</dd></div>
              <div><dt className="text-gray-500">الوصف</dt><dd>{selected.description ?? '—'}</dd></div>
              <div>
                <dt className="text-gray-500">التوثيق</dt>
                <dd>{selected.isVerified ? 'موثقة' : 'غير موثقة'}</dd>
              </div>
              <div>
                <dt className="text-gray-500">التفعيل على المنصة</dt>
                <dd>{selected.isActiveOnPlatform ? 'مفعّلة' : 'غير مفعّلة'}</dd>
              </div>
              <div>
                <dt className="text-gray-500">الحالة المعروضة</dt>
                <dd>{COMPANY_STATUS_LABELS[selected.displayStatus]}</dd>
              </div>
            </dl>
            <div className="mt-4">
              <p className="text-sm font-medium mb-2">السجل التجاري (ملف)</p>
              <FilePreview url={selected.commercialRegisterURL} />
            </div>
          </div>
        </div>
      )}

      <ConfirmModal
        isOpen={!!action}
        onClose={() => setAction(null)}
        onConfirm={confirm}
        title={
          action === 'verify' ? 'تبديل حالة التوثيق' :
          action === 'active' ? 'تبديل حالة التفعيل' : 'حذف الشركة'
        }
        message={
          action === 'verify'
            ? 'تبديل حالة توثيق الشركة؟ (منفصلة عن التفعيل)'
            : action === 'active'
              ? 'تبديل حالة تفعيل الشركة على المنصة؟'
              : 'هل أنت متأكد من حذف هذه الشركة؟'
        }
        isLoading={verifyMut.isPending || activeMut.isPending || deleteMut.isPending}
      />
    </div>
  );
}
