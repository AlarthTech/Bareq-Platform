import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Check, Eye } from 'lucide-react';
import { useMemo, useState } from 'react';
import { companiesApi } from '../../api/companies.api';
import { usePendingCompanies } from '../../hooks/usePendingCompanies';
import { useCompaniesWithStatus } from '../../hooks/useCompaniesWithStatus';
import { formatDate } from '../../core/utils';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { FilePreview } from '../../shared/components/FilePreview';
import { CompanyStatusBadge } from '../../shared/components/CompanyStatusBadge';
import { useToast } from '../../shared/context/ToastContext';
import type { CompanyWithStatus } from '../../hooks/useCompaniesWithStatus';

export default function PendingCompaniesPage() {
  const [detail, setDetail] = useState<CompanyWithStatus | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { pending, paged, isLoading, setPage, setPageSize } = usePendingCompanies();
  const { companies: pendingWithStatus, isLoading: statusLoading } = useCompaniesWithStatus(pending);

  const pagedWithStatus = useMemo(() => {
    const statusMap = new Map(pendingWithStatus.map((c) => [c.id, c]));
    return {
      ...paged,
      items: paged.items.map((c) => statusMap.get(c.id) ?? { ...c, displayStatus: 'pending' as const, isActiveOnPlatform: false }),
    };
  }, [paged, pendingWithStatus]);

  const approveMut = useMutation({
    mutationFn: (id: number) => companiesApi.approve(id),
    onSuccess: (r) => {
      showToast(r.message, 'success');
      qc.invalidateQueries({ queryKey: ['companies'] });
      setDetail(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div>
      <PageHeader
        title="طلبات التحقق"
        subtitle={`شركات بانتظار الاعتماد — ${pending.length} طلب`}
      />
      <DataTable<CompanyWithStatus>
        isLoading={isLoading || statusLoading}
        data={pagedWithStatus.items}
        paged={pagedWithStatus}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        emptyMessage="لا توجد طلبات معلقة"
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'name', header: 'اسم الشركة' },
          { key: 'ownerUserName', header: 'المالك', render: (c) => c.ownerUserName ?? '—' },
          { key: 'cityName', header: 'المدينة', render: (c) => c.cityName ?? '—' },
          { key: 'phone', header: 'الهاتف' },
          { key: 'createdAt', header: 'تاريخ الطلب', render: (c) => formatDate(c.createdAt) },
          {
            key: 'displayStatus',
            header: 'الحالة',
            render: (c) => <CompanyStatusBadge status={c.displayStatus} />,
          },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (c) => (
              <div className="flex gap-2 justify-end">
                <button type="button" onClick={() => setDetail(c)} className="text-gray-600 hover:text-bareq-600">
                  <Eye className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => approveMut.mutate(c.id)}
                  className="inline-flex items-center gap-1 text-sm text-green-600 hover:text-green-700"
                  title="اعتماد الشركة وتفعيلها"
                >
                  <Check className="w-4 h-4" />
                  اعتماد
                </button>
              </div>
            ),
          },
        ]}
      />

      {detail && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={() => setDetail(null)}>
          <div className="bg-white rounded-xl max-w-lg w-full p-6" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold mb-4">{detail.name}</h3>
            <div className="mb-4">
              <CompanyStatusBadge status={detail.displayStatus} />
            </div>
            <FilePreview url={detail.commercialRegisterURL} label="عرض السجل التجاري" />
            <p className="text-xs text-amber-700 mt-3 bg-amber-50 rounded-lg p-2">
              الاعتماد يوثّق الشركة ويفعّلها على المنصة.
            </p>
            <button
              type="button"
              onClick={() => approveMut.mutate(detail.id)}
              disabled={approveMut.isPending}
              className="mt-4 w-full py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
            >
              اعتماد الشركة
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
