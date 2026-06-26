import { useMemo, useState } from 'react';
import { Plus, Pencil, Trash2, Ban, Search } from 'lucide-react';
import type { PagedResult } from '../../../types/api.types';
import type {
  CreateReferenceForm,
  CreateReferenceItem,
  ReferenceItem,
  UpdateReferenceForm,
  UpdateReferenceItem,
} from '../../../types/reference.types';
import { toCreatePayload, toUpdatePayload } from '../../../types/reference.types';
import { PageHeader } from '../../../shared/components/PageHeader';
import { DataTable } from '../../../shared/tables/DataTable';
import { ConfirmModal } from '../../../shared/components/ConfirmModal';
import { Button } from '../../../shared/ui/Button';
import { useToast } from '../../../shared/context/ToastContext';
import { getErrorMessage } from '../../../core/utils/getErrorMessage';
import { ActiveStatusBadge } from './ActiveStatusBadge';
import { ReferenceFormModal } from './ReferenceFormModal';

interface MutationLike<TVar = void> {
  mutateAsync: (variables: TVar) => Promise<unknown>;
  isPending: boolean;
}

interface ReferenceDataPageProps {
  title: string;
  subtitle: string;
  addLabel: string;
  paginated: boolean;
  canDelete: boolean;
  removeLabel: string;
  confirmRemoveMessage: string;
  isLoading: boolean;
  items: ReferenceItem[];
  paged?: Pick<
    PagedResult<ReferenceItem>,
    'page' | 'pageSize' | 'totalCount' | 'totalPages' | 'hasNextPage' | 'hasPreviousPage'
  >;
  onPageChange?: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
  createMutation: MutationLike<CreateReferenceItem>;
  updateMutation: MutationLike<{ id: number; data: UpdateReferenceItem }>;
  removeMutation: MutationLike<number>;
}

export function ReferenceDataPage({
  title,
  subtitle,
  addLabel,
  paginated,
  canDelete,
  removeLabel,
  confirmRemoveMessage,
  isLoading,
  items,
  paged,
  onPageChange,
  onPageSizeChange,
  createMutation,
  updateMutation,
  removeMutation,
}: ReferenceDataPageProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editItem, setEditItem] = useState<ReferenceItem | null>(null);
  const [removeItem, setRemoveItem] = useState<ReferenceItem | null>(null);
  const [search, setSearch] = useState('');
  const { showToast } = useToast();

  const filtered = useMemo(() => {
    if (paginated || !search.trim()) return items;
    const q = search.trim().toLowerCase();
    return items.filter(
      (item) =>
        item.name.toLowerCase().includes(q) ||
        item.code?.toLowerCase().includes(q)
    );
  }, [items, search, paginated]);

  const handleCreate = async (data: CreateReferenceForm | UpdateReferenceForm) => {
    try {
      await createMutation.mutateAsync(toCreatePayload(data as CreateReferenceForm));
      showToast('تمت الإضافة بنجاح', 'success');
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
      throw e;
    }
  };

  const handleUpdate = async (data: CreateReferenceForm | UpdateReferenceForm) => {
    if (!editItem) return;
    try {
      await updateMutation.mutateAsync({ id: editItem.id, data: toUpdatePayload(data) });
      showToast('تم الحفظ بنجاح', 'success');
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
      throw e;
    }
  };

  const handleRemove = async () => {
    if (!removeItem) return;
    try {
      await removeMutation.mutateAsync(removeItem.id);
      showToast(canDelete ? 'تم الحذف بنجاح' : 'تم التعطيل بنجاح', 'success');
      setRemoveItem(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const openCreate = () => {
    setEditItem(null);
    setModalOpen(true);
  };

  const openEdit = (item: ReferenceItem) => {
    setEditItem(item);
    setModalOpen(true);
  };

  const closeModal = () => {
    setModalOpen(false);
    setEditItem(null);
  };

  return (
    <div>
      <PageHeader
        title={title}
        subtitle={subtitle}
        actions={
          <Button
            type="button"
            onClick={openCreate}
            className="!bg-bareq-600 hover:!bg-bareq-700 inline-flex items-center gap-2"
          >
            <Plus className="w-4 h-4" />
            {addLabel}
          </Button>
        }
      />

      <DataTable<ReferenceItem>
        isLoading={isLoading}
        data={filtered}
        paged={paginated ? paged : undefined}
        onPageChange={paginated ? onPageChange : undefined}
        onPageSizeChange={paginated ? onPageSizeChange : undefined}
        toolbar={
          !paginated ? (
            <div className="relative max-w-sm">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="search"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="بحث بالاسم أو الرمز..."
                className="w-full pr-10 pl-3 py-2 border border-gray-200 rounded-lg text-sm"
              />
            </div>
          ) : undefined
        }
        columns={[
          { key: 'id', header: '#' },
          { key: 'name', header: 'الاسم' },
          { key: 'code', header: 'الرمز', render: (item) => item.code ?? '—' },
          {
            key: 'isActive',
            header: 'الحالة',
            render: (item) => <ActiveStatusBadge isActive={item.isActive} />,
          },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (item) => (
              <div className="flex gap-1 justify-end">
                <button
                  type="button"
                  onClick={() => openEdit(item)}
                  className="p-1.5 text-blue-600 hover:bg-blue-50 rounded"
                  title="تعديل"
                >
                  <Pencil className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setRemoveItem(item)}
                  className="p-1.5 text-red-600 hover:bg-red-50 rounded"
                  title={removeLabel}
                >
                  {canDelete ? <Trash2 className="w-4 h-4" /> : <Ban className="w-4 h-4" />}
                </button>
              </div>
            ),
          },
        ]}
      />

      <ReferenceFormModal
        isOpen={modalOpen}
        onClose={closeModal}
        onSubmit={editItem ? handleUpdate : handleCreate}
        item={editItem}
        isLoading={createMutation.isPending || updateMutation.isPending}
      />

      <ConfirmModal
        isOpen={removeItem !== null}
        onClose={() => setRemoveItem(null)}
        onConfirm={handleRemove}
        title={removeLabel}
        message={confirmRemoveMessage}
        confirmText={canDelete ? 'حذف' : 'تعطيل'}
        cancelText="إلغاء"
        isLoading={removeMutation.isPending}
      />
    </div>
  );
}
