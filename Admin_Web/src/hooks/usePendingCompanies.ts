import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { companiesApi } from '../api/companies.api';
import { usePagination } from '../core/hooks/usePagination';
import { paginateItems } from '../core/utils/paginateItems';

export function usePendingCompanies() {
  const { page, pageSize, setPage, setPageSize } = usePagination();

  const { data: allCompanies = [], isLoading, isError, refetch } = useQuery({
    queryKey: ['companies', 'all'],
    queryFn: companiesApi.fetchAll,
  });

  const pending = useMemo(
    () => allCompanies.filter((c) => !c.isVerified),
    [allCompanies]
  );

  const paged = useMemo(
    () => paginateItems(pending, page, pageSize),
    [pending, page, pageSize]
  );

  return {
    pending,
    paged,
    isLoading,
    isError,
    refetch,
    page,
    pageSize,
    setPage,
    setPageSize,
  };
}
