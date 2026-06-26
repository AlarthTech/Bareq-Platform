import {
  useNationalities,
  useCreateNationality,
  useUpdateNationality,
  useDeactivateNationality,
} from '../../hooks/useNationalities';
import { ReferenceDataPage } from './components/ReferenceDataPage';

export default function NationalitiesPage() {
  const { data = [], isLoading } = useNationalities();
  const createMutation = useCreateNationality();
  const updateMutation = useUpdateNationality();
  const deactivateMutation = useDeactivateNationality();

  return (
    <ReferenceDataPage
      title="الجنسيات"
      subtitle="البيانات المرجعية — إدارة الجنسيات"
      addLabel="إضافة جنسية"
      paginated={false}
      canDelete={false}
      removeLabel="تعطيل الجنسية"
      confirmRemoveMessage="هل تريد تعطيل هذه الجنسية؟ ستختفي من القائمة العامة."
      isLoading={isLoading}
      items={data}
      createMutation={createMutation}
      updateMutation={updateMutation}
      removeMutation={deactivateMutation}
    />
  );
}
