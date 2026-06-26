import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { bookingsApi } from '../api/bookings.api';
import { usePagination } from '../core/hooks/usePagination';
import { paginateItems } from '../core/utils/paginateItems';
import type { PagedResult, Booking } from '../types/api.types';
import {
  type BookingDisplayStatusFilter,
  matchesDisplayStatusFilter,
} from '../features/bookings/utils/bookingDisplayStatus';

export function useBookingsList() {
  const { page, pageSize, setPage, setPageSize } = usePagination();
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [displayStatusFilter, setDisplayStatusFilter] = useState<string>('');

  const needsClientFilter = statusFilter !== '' || displayStatusFilter !== '';

  const serverQuery = useQuery({
    queryKey: ['bookings', page, pageSize],
    queryFn: () => bookingsApi.getAll({ page, pageSize }),
    enabled: !needsClientFilter,
  });

  const allQuery = useQuery({
    queryKey: ['bookings', 'all'],
    queryFn: bookingsApi.fetchAll,
    enabled: needsClientFilter,
  });

  const filtered = useMemo(() => {
    if (!needsClientFilter) return [];
    let items = allQuery.data ?? [];

    if (statusFilter !== '') {
      items = items.filter((b) => b.status === Number(statusFilter));
    }

    if (displayStatusFilter !== '') {
      items = items.filter((b) =>
        matchesDisplayStatusFilter(b, displayStatusFilter as BookingDisplayStatusFilter)
      );
    }

    return items;
  }, [allQuery.data, statusFilter, displayStatusFilter, needsClientFilter]);

  const clientPaged = useMemo(
    () => (needsClientFilter ? paginateItems(filtered, page, pageSize) : null),
    [filtered, page, pageSize, needsClientFilter]
  );

  const data: PagedResult<Booking> | undefined =
    !needsClientFilter ? serverQuery.data : clientPaged ?? undefined;

  const items = data?.items ?? [];
  const isLoading = !needsClientFilter ? serverQuery.isLoading : allQuery.isLoading;

  const setStatusFilterAndReset = (value: string) => {
    setStatusFilter(value);
    setPage(1);
  };

  const setDisplayStatusFilterAndReset = (value: string) => {
    setDisplayStatusFilter(value);
    setPage(1);
  };

  return {
    items,
    data,
    isLoading,
    statusFilter,
    setStatusFilter: setStatusFilterAndReset,
    displayStatusFilter,
    setDisplayStatusFilter: setDisplayStatusFilterAndReset,
    page,
    pageSize,
    setPage,
    setPageSize,
  };
}
