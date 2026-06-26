import { useState, useCallback } from 'react';
import { PAGINATION } from '../constants';

export function usePagination(initialPageSize: number = PAGINATION.DEFAULT_PAGE_SIZE) {
  const [page, setPage] = useState<number>(PAGINATION.DEFAULT_PAGE);
  const [pageSize, setPageSizeState] = useState<number>(initialPageSize);

  const resetPage = useCallback(() => setPage(PAGINATION.DEFAULT_PAGE), []);

  const setPageSize = useCallback((size: number) => {
    setPageSizeState(Math.min(size, PAGINATION.MAX_PAGE_SIZE));
    setPage(PAGINATION.DEFAULT_PAGE);
  }, []);

  return { page, pageSize, setPage, setPageSize, resetPage };
}
