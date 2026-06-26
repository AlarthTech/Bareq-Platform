import type { ReactNode } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { PAGINATION } from '../../core/constants';
import type { PagedResult } from '../../types/api.types';

interface Column<T> {
  key: string;
  header: string;
  render?: (item: T) => ReactNode;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  isLoading?: boolean;
  emptyMessage?: string;
  paged?: Pick<
    PagedResult<T>,
    'page' | 'pageSize' | 'totalCount' | 'totalPages' | 'hasNextPage' | 'hasPreviousPage'
  >;
  /** @deprecated use paged */
  pagination?: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
  onPageChange?: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
  onSearch?: (query: string) => void;
  searchPlaceholder?: string;
  toolbar?: ReactNode;
}

export function DataTable<T extends { id?: number | string }>({
  columns,
  data,
  isLoading,
  emptyMessage = 'لا توجد بيانات',
  paged: pagedProp,
  pagination,
  onPageChange,
  onPageSizeChange,
  onSearch,
  searchPlaceholder = 'بحث...',
  toolbar,
}: DataTableProps<T>) {
  const paged = pagedProp ?? (pagination
    ? {
        page: pagination.page,
        pageSize: pagination.pageSize,
        totalCount: pagination.total,
        totalPages: pagination.totalPages,
        hasNextPage: pagination.page < pagination.totalPages,
        hasPreviousPage: pagination.page > 1,
      }
    : undefined);
  if (isLoading) {
    return (
      <div className="bg-white rounded-xl border border-gray-200 p-8">
        <div className="animate-pulse space-y-3">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-10 bg-gray-100 rounded" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      {toolbar && <div className="p-4 border-b border-gray-100">{toolbar}</div>}
      {onSearch && !toolbar && (
        <div className="p-4 border-b border-gray-100">
          <input
            type="search"
            placeholder={searchPlaceholder}
            onChange={(e) => onSearch(e.target.value)}
            className="w-full max-w-sm border border-gray-200 rounded-lg px-3 py-2 text-sm"
          />
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              {columns.map((col) => (
                <th
                  key={col.key}
                  className="px-4 py-3 text-right text-xs font-semibold text-gray-600"
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {data.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="px-4 py-16 text-center text-gray-500">
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              data.map((item, idx) => (
                <tr key={item.id ?? idx} className="hover:bg-gray-50/80">
                  {columns.map((col) => (
                    <td key={col.key} className="px-4 py-3 text-right text-gray-900">
                      {col.render ? col.render(item) : (item as Record<string, unknown>)[col.key] as ReactNode}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {paged && onPageChange && (
        <div className="px-4 py-3 border-t border-gray-100 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <span>عدد الصفوف:</span>
            <select
              value={paged.pageSize}
              onChange={(e) => onPageSizeChange?.(Number(e.target.value))}
              className="border border-gray-200 rounded-lg px-2 py-1"
            >
              {PAGINATION.PAGE_SIZE_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
            <span className="mr-2">الإجمالي: {paged.totalCount}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600">
              صفحة {paged.page} من {paged.totalPages || 1}
            </span>
            <button
              type="button"
              disabled={!paged.hasPreviousPage}
              onClick={() => onPageChange(paged.page - 1)}
              className="p-2 rounded-lg border border-gray-200 disabled:opacity-40 hover:bg-gray-50"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
            <button
              type="button"
              disabled={!paged.hasNextPage}
              onClick={() => onPageChange(paged.page + 1)}
              className="p-2 rounded-lg border border-gray-200 disabled:opacity-40 hover:bg-gray-50"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
