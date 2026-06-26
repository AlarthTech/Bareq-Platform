import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { usersApi } from '../../api';
import { DataTable } from '../../../../shared/tables/DataTable';
import { StatusBadge } from '../../../../shared/components/StatusBadge';
import { PageHeader } from '../../../../shared/components/PageHeader';
import { ConfirmModal } from '../../../../shared/components/ConfirmModal';
import { Button } from '../../../../shared/ui/Button';
import { formatDate } from '../../../../core/utils';
import { PAGINATION } from '../../../../core/constants';
import { useDebounce } from '../../../../core/hooks/useDebounce';
import type { Customer } from '../../types';

export default function CustomersPage() {
  const [page, setPage] = useState<number>(PAGINATION.DEFAULT_PAGE);
  const [pageSize, setPageSize] = useState<number>(PAGINATION.DEFAULT_PAGE_SIZE);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUser, setSelectedUser] = useState<{ id: string; status: string } | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const debouncedSearch = useDebounce(searchQuery, 500);
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['customers', page, pageSize, debouncedSearch],
    queryFn: () => usersApi.getCustomers({ page, pageSize, search: debouncedSearch }),
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ userId, status }: { userId: string; status: string }) =>
      usersApi.updateUserStatus(userId, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['customers'] });
      setIsModalOpen(false);
      setSelectedUser(null);
    },
  });

  const handleStatusChange = (user: Customer, newStatus: string) => {
    setSelectedUser({ id: user.id, status: newStatus });
    setIsModalOpen(true);
  };

  const handleConfirm = () => {
    if (selectedUser) {
      updateStatusMutation.mutate({
        userId: selectedUser.id,
        status: selectedUser.status,
      });
    }
  };

  const columns = [
    {
      key: 'name',
      header: 'Name',
    },
    {
      key: 'email',
      header: 'Email',
    },
    {
      key: 'phone',
      header: 'Phone',
    },
    {
      key: 'totalBookings',
      header: 'Total Bookings',
    },
    {
      key: 'status',
      header: 'Status',
      render: (item: Customer) => <StatusBadge status={item.status} />,
    },
    {
      key: 'createdAt',
      header: 'Created At',
      render: (item: Customer) => formatDate(item.createdAt),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (item: Customer) => (
        <div className="flex gap-2">
          {item.status === 'active' ? (
            <Button
              variant="outline"
              size="sm"
              onClick={() => handleStatusChange(item, 'inactive')}
            >
              Deactivate
            </Button>
          ) : (
            <Button
              variant="primary"
              size="sm"
              onClick={() => handleStatusChange(item, 'active')}
            >
              Activate
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div>
      <PageHeader
        title="Customers"
        breadcrumbs={[{ label: 'Users', path: '/users' }, { label: 'Customers' }]}
      />

      <DataTable
        data={data?.data || []}
        columns={columns}
        isLoading={isLoading}
        pagination={data?.pagination}
        onPageChange={setPage}
        onPageSizeChange={(newSize) => {
          setPageSize(newSize);
          setPage(1);
        }}
        onSearch={setSearchQuery}
        searchPlaceholder="Search by name or email..."
        emptyMessage="No customers found"
      />

      <ConfirmModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedUser(null);
        }}
        onConfirm={handleConfirm}
        title="Confirm Status Change"
        message={`Are you sure you want to ${selectedUser?.status === 'active' ? 'activate' : 'deactivate'} this customer?`}
        isLoading={updateStatusMutation.isPending}
      />
    </div>
  );
}
