import {
  useLanguages,
  useCreateLanguage,
  useUpdateLanguage,
  useDeactivateLanguage,
} from '../../hooks/useLanguages';
import { ReferenceDataPage } from './components/ReferenceDataPage';

export default function LanguagesPage() {
  const { data = [], isLoading } = useLanguages();
  const createMutation = useCreateLanguage();
  const updateMutation = useUpdateLanguage();
  const deactivateMutation = useDeactivateLanguage();

  return (
    <ReferenceDataPage
      title="اللغات"
      subtitle="البيانات المرجعية — إدارة اللغات"
      addLabel="إضافة لغة"
      paginated={false}
      canDelete={false}
      removeLabel="تعطيل اللغة"
      confirmRemoveMessage="هل تريد تعطيل هذه اللغة؟ ستختفي من القائمة العامة."
      isLoading={isLoading}
      items={data}
      createMutation={createMutation}
      updateMutation={updateMutation}
      removeMutation={deactivateMutation}
    />
  );
}
