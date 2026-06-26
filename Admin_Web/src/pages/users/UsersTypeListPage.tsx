import { useMemo, useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Trash2 } from 'lucide-react';
import { usersApi } from '../../api/users.api';
import { usePagination } from '../../core/hooks/usePagination';
import { useAllUsers } from '../../hooks/useAllUsers';
import { formatDate } from '../../core/utils';
import { paginateItems } from '../../core/utils/paginateItems';
import { PageHeader } from '../../shared/components/PageHeader';
import { DataTable } from '../../shared/tables/DataTable';
import { ConfirmModal } from '../../shared/components/ConfirmModal';
import { useToast } from '../../shared/context/ToastContext';
import type { AppUser } from '../../types/api.types';

export type UserTypeFilter = 'Admin' | 'Company' | 'Customer';

interface UsersTypeListPageProps {
  userType: UserTypeFilter;
  title: string;
  subtitle: string;
}

function matchesUserType(userTypeName: string, filter: UserTypeFilter): boolean {
  return userTypeName.toLowerCase() === filter.toLowerCase();
}

export function UsersTypeListPage({ userType, title, subtitle }: UsersTypeListPageProps) {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const qc = useQueryClient();
  const { showToast } = useToast();

  const { data: allUsers = [], isLoading } = useAllUsers();

  const filtered = useMemo(
    () => allUsers.filter((u) => matchesUserType(u.userTypeName, userType)),
    [allUsers, userType]
  );

  const paged = useMemo(
    () => paginateItems(filtered, page, pageSize),
    [filtered, page, pageSize]
  );

  const deleteMutation = useMutation({
    mutationFn: usersApi.delete,
    onSuccess: () => {
      showToast('تم حذف المستخدم', 'success');
      qc.invalidateQueries({ queryKey: ['users'] });
      setDeleteId(null);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div>
      <PageHeader
        title={title}
        subtitle={`${subtitle} — ${filtered.length} مستخدم`}
      />
      <DataTable<AppUser>
        isLoading={isLoading}
        data={paged.items}
        paged={paged}
        onPageChange={setPage}
        onPageSizeChange={setPageSize}
        emptyMessage={`لا يوجد ${title}`}
        columns={[
          { key: 'id', header: 'المعرف' },
          { key: 'fullName', header: 'الاسم' },
          { key: 'email', header: 'البريد' },
          { key: 'phone', header: 'الهاتف' },
          { key: 'createdAt', header: 'تاريخ التسجيل', render: (u) => formatDate(u.createdAt) },
          {
            key: 'actions',
            header: 'إجراءات',
            render: (u) => (
              <button
                type="button"
                onClick={() => setDeleteId(u.id)}
                className="text-red-600 hover:text-red-700 p-1"
                title="حذف"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            ),
          },
        ]}
      />
      <ConfirmModal
        isOpen={deleteId !== null}
        onClose={() => setDeleteId(null)}
        onConfirm={() => deleteId && deleteMutation.mutate(deleteId)}
        title="حذف المستخدم"
        message="هل أنت متأكد؟ سيتم تعطيل الحساب."
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
