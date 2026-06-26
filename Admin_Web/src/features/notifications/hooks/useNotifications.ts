import { useEffect, useState } from 'react';
import {
  useInfiniteQuery,
  useQuery,
  useMutation,
  useQueryClient,
  type InfiniteData,
} from '@tanstack/react-query';
import { notificationsApi } from '../api/notificationsApi';
import type { NotificationDTO } from '../types';
import { notificationRealtimeService, type HubConnectionState } from '../services/notificationRealtimeService';
import type { PagedResult } from '../../../types/api.types';
import { useAuthStore } from '../../../core/auth/store';
import {
  LIST_KEY,
  PAGE_SIZE,
  UNREAD_KEY,
} from './useRealtimeSync';

export { useNotificationHubSync, useBookingRealtimeSync } from './useRealtimeSync';

export function useUnreadCount(hubConnected: boolean) {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);

  return useQuery({
    queryKey: UNREAD_KEY,
    queryFn: async () => {
      const data = await notificationsApi.getUnreadCount();
      return typeof data === 'number' ? data : (data as { count?: number }).count ?? 0;
    },
    enabled: isAuthenticated,
    retry: 1,
    staleTime: 30_000,
    refetchInterval: hubConnected ? false : 60_000,
  });
}

export function useNotificationsInfinite(enabled: boolean) {
  return useInfiniteQuery({
    queryKey: LIST_KEY,
    queryFn: ({ pageParam }) => notificationsApi.getMyNotifications(pageParam, PAGE_SIZE),
    initialPageParam: 1,
    getNextPageParam: (last) => (last.hasNextPage ? last.page + 1 : undefined),
    enabled,
    retry: 1,
  });
}

export function useNotificationMutations() {
  const qc = useQueryClient();

  const markAsRead = useMutation({
    mutationFn: (id: number) => notificationsApi.markAsRead(id),
    onSuccess: (_, id) => {
      qc.setQueryData<number>(UNREAD_KEY, (old) => Math.max(0, (old ?? 1) - 1));
      patchNotificationRead(qc, id, true);
    },
  });

  const markAllAsRead = useMutation({
    mutationFn: () => notificationsApi.markAllAsRead(),
    onSuccess: () => {
      qc.setQueryData(UNREAD_KEY, 0);
      qc.setQueryData<InfiniteData<PagedResult<NotificationDTO>>>(LIST_KEY, (old) => {
        if (!old) return old;
        return {
          ...old,
          pages: old.pages.map((p) => ({
            ...p,
            items: p.items.map((n) => ({ ...n, isRead: true })),
          })),
        };
      });
    },
  });

  return { markAsRead, markAllAsRead };
}

function patchNotificationRead(
  qc: ReturnType<typeof useQueryClient>,
  id: number,
  isRead: boolean
) {
  qc.setQueryData<InfiniteData<PagedResult<NotificationDTO>>>(LIST_KEY, (old) => {
    if (!old) return old;
    return {
      ...old,
      pages: old.pages.map((p) => ({
        ...p,
        items: p.items.map((n) => (n.id === id ? { ...n, isRead } : n)),
      })),
    };
  });
}

export function useHubConnectionState(): HubConnectionState {
  const { isAuthenticated } = useAuthStore();
  const [state, setState] = useState<HubConnectionState>('disconnected');

  useEffect(() => {
    if (!isAuthenticated) {
      setState('disconnected');
      return;
    }
    return notificationRealtimeService.subscribeState(setState);
  }, [isAuthenticated]);

  return state;
}

export function useNewNotificationPulse(unreadCount: number): boolean {
  const [pulse, setPulse] = useState(false);
  const [prev, setPrev] = useState(unreadCount);

  useEffect(() => {
    if (unreadCount > prev) {
      setPulse(true);
      const timer = window.setTimeout(() => setPulse(false), 600);
      setPrev(unreadCount);
      return () => window.clearTimeout(timer);
    }
    setPrev(unreadCount);
  }, [unreadCount, prev]);

  return pulse;
}
