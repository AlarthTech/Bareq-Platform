import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { bookingsApi } from '../../api';
import { DataTable } from '../../../../shared/tables/DataTable';
import { StatusBadge } from '../../../../shared/components/StatusBadge';
import { PageHeader } from '../../../../shared/components/PageHeader';
import { formatDate, formatCurrency } from '../../../../core/utils';
import { PAGINATION } from '../../../../core/constants';
import { useDebounce } from '../../../../core/hooks/useDebounce';
import type { Booking } from '../../types';

export default function BookingsPage() {
  const [page, setPage] = useState<number>(PAGINATION.DEFAULT_PAGE);
  const [pageSize, setPageSize] = useState<number>(PAGINATION.DEFAULT_PAGE_SIZE);
  const [searchQuery, setSearchQuery] = useState('');

  const debouncedSearch = useDebounce(searchQuery, 500);

  const { data, isLoading } = useQuery({
    queryKey: ['bookings', page, pageSize, debouncedSearch],
    queryFn: () => bookingsApi.getBookings({ page, pageSize, search: debouncedSearch }),
  });

  const columns = [
    {
      key: 'customerName',
      header: 'Customer',
      render: (item: Booking) => (
        <div>
          <div className="font-medium">{item.customerName}</div>
          <div className="text-xs text-gray-500">{item.customerEmail}</div>
        </div>
      ),
    },
    {
      key: 'companyName',
      header: 'Company',
    },
    {
      key: 'workerName',
      header: 'Worker',
    },
    {
      key: 'serviceDate',
      header: 'Service Date',
      render: (item: Booking) => (
        <div>
          <div>{formatDate(item.serviceDate)}</div>
          <div className="text-xs text-gray-500">{item.serviceTime}</div>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (item: Booking) => <StatusBadge status={item.status as any} />,
    },
    {
      key: 'totalAmount',
      header: 'Amount',
      render: (item: Booking) => formatCurrency(item.totalAmount),
    },
    {
      key: 'createdAt',
      header: 'Created At',
      render: (item: Booking) => formatDate(item.createdAt),
    },
  ];

  return (
    <div>
      <PageHeader title="Bookings" />

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
        searchPlaceholder="Search bookings..."
        emptyMessage="No bookings found"
      />
    </div>
  );
}
