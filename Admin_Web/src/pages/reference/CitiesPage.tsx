import { usePagination } from '../../core/hooks/usePagination';
import {
  useCities,
  useCreateCity,
  useUpdateCity,
  useDeleteCity,
} from '../../hooks/useCities';
import { ReferenceDataPage } from './components/ReferenceDataPage';

export default function CitiesPage() {
  const { page, pageSize, setPage, setPageSize } = usePagination(20);
  const { data, isLoading } = useCities(page, pageSize);
  const createMutation = useCreateCity();
  const updateMutation = useUpdateCity();
  const deleteMutation = useDeleteCity();

  return (
    <ReferenceDataPage
      title="المدن"
      subtitle="البيانات المرجعية — إدارة المدن"
      addLabel="إضافة مدينة"
      paginated
      canDelete
      removeLabel="حذف المدينة"
      confirmRemoveMessage="هل تريد حذف هذه المدينة؟"
      isLoading={isLoading}
      items={data?.items ?? []}
      paged={data}
      onPageChange={setPage}
      onPageSizeChange={setPageSize}
      createMutation={createMutation}
      updateMutation={updateMutation}
      removeMutation={deleteMutation}
    />
  );
}
