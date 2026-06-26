import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Loader2, RefreshCw } from 'lucide-react';
import { NotificationItem } from './NotificationItem';
import type { NotificationDTO } from '../types';
import { NOTIFICATION_GROUP_LABELS } from '../types';
import { groupNotificationsByDate } from '../utils/groupByDate';
import { getNotificationRoute } from '../utils/getNotificationRoute';
import {
  useNotificationsInfinite,
  useNotificationMutations,
} from '../hooks/useNotifications';
import { Button } from '../../../shared/ui/Button';

interface NotificationDropdownProps {
  open: boolean;
  onClose: () => void;
}

export function NotificationDropdown({ open, onClose }: NotificationDropdownProps) {
  const navigate = useNavigate();
  const scrollRef = useRef<HTMLDivElement>(null);
  const { markAsRead, markAllAsRead } = useNotificationMutations();

  const {
    data,
    isLoading,
    isError,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useNotificationsInfinite(open);

  const allItems: NotificationDTO[] =
    data?.pages.flatMap((p) => p.items) ?? [];
  const grouped = groupNotificationsByDate(allItems);

  const handleClick = async (notification: NotificationDTO) => {
    if (!notification.isRead) {
      try {
        await markAsRead.mutateAsync(notification.id);
      } catch {
        /* non-blocking */
      }
    }
    const route = getNotificationRoute(notification);
    onClose();
    if (route) navigate(route);
  };

  const handleMarkAll = async () => {
    try {
      await markAllAsRead.mutateAsync();
    } catch {
      /* ignore */
    }
  };

  useEffect(() => {
    if (open) {
      refetch();
    }
  }, [open, refetch]);

  return (
    <div className="absolute left-0 mt-2 w-[min(24rem,calc(100vw-2rem))] rounded-xl bg-white shadow-xl ring-1 ring-black/5 z-50 overflow-hidden">
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100">
        <h3 className="font-semibold text-gray-900">الإشعارات</h3>
        {allItems.some((n) => !n.isRead) && (
          <button
            type="button"
            onClick={handleMarkAll}
            disabled={markAllAsRead.isPending}
            className="text-xs text-bareq-600 hover:text-bareq-700 font-medium disabled:opacity-50"
          >
            تعليم الكل كمقروء
          </button>
        )}
      </div>

      <div ref={scrollRef} className="max-h-[min(24rem,60vh)] overflow-y-auto">
        {isLoading && (
          <div className="p-6 space-y-3 animate-pulse">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-16 bg-gray-100 rounded-lg" />
            ))}
          </div>
        )}

        {isError && (
          <div className="p-6 text-center">
            <p className="text-sm text-gray-500 mb-3">تعذر تحميل الإشعارات</p>
            <Button type="button" variant="outline" size="sm" onClick={() => refetch()}>
              <RefreshCw className="w-4 h-4 ml-1" />
              إعادة المحاولة
            </Button>
          </div>
        )}

        {!isLoading && !isError && allItems.length === 0 && (
          <p className="p-8 text-center text-sm text-gray-500">لا توجد إشعارات</p>
        )}

        {!isLoading &&
          !isError &&
          grouped.map(({ group, items }) => (
            <div key={group}>
              <p className="px-4 py-2 text-xs font-semibold text-gray-400 bg-gray-50 sticky top-0">
                {NOTIFICATION_GROUP_LABELS[group]}
              </p>
              {items.map((n) => (
                <NotificationItem key={n.id} notification={n} onClick={() => handleClick(n)} />
              ))}
            </div>
          ))}

        {hasNextPage && !isLoading && (
          <div className="p-3 border-t border-gray-100">
            <button
              type="button"
              onClick={() => fetchNextPage()}
              disabled={isFetchingNextPage}
              className="w-full py-2 text-sm text-bareq-600 hover:bg-gray-50 rounded-lg disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {isFetchingNextPage ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  جاري التحميل...
                </>
              ) : (
                'تحميل المزيد'
              )}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
