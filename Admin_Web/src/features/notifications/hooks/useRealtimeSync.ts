import { useEffect } from 'react';
import { useQueryClient, type InfiniteData } from '@tanstack/react-query';
import { useAuthStore } from '../../../core/auth/store';
import { useToast } from '../../../shared/context/ToastContext';
import type { PagedResult } from '../../../types/api.types';
import { notificationRealtimeService } from '../services/notificationRealtimeService';
import type { BookingStatusChangedPayload, NotificationDTO } from '../types';
import { bookingEventToNotification } from '../utils/bookingEventToNotification';
import { isBookingNotificationType, mapStatusNameToValue } from '../utils/mapBookingStatus';
import { patchBookingStatusInCache } from '../utils/patchBookingCache';
import { getNotificationText } from '../utils/notificationText';

export const UNREAD_KEY = ['notifications', 'unread-count'] as const;
export const LIST_KEY = ['notifications', 'list'] as const;
export const PAGE_SIZE = 20;

const recentEventIds = new Set<number>();

function shouldProcessEvent(id: number): boolean {
  if (recentEventIds.has(id)) return false;
  recentEventIds.add(id);
  window.setTimeout(() => recentEventIds.delete(id), 3000);
  return true;
}

export function prependNotification(
  qc: ReturnType<typeof useQueryClient>,
  notification: NotificationDTO
) {
  qc.setQueryData<InfiniteData<PagedResult<NotificationDTO>>>(LIST_KEY, (old) => {
    if (!old?.pages?.length) {
      return {
        pages: [
          {
            items: [notification],
            page: 1,
            pageSize: PAGE_SIZE,
            totalCount: 1,
            totalPages: 1,
            hasNextPage: false,
            hasPreviousPage: false,
          },
        ],
        pageParams: [1],
      };
    }
    const exists = old.pages.some((p) => p.items.some((n) => n.id === notification.id));
    if (exists) return old;

    const first = old.pages[0];
    return {
      ...old,
      pages: [{ ...first, items: [notification, ...first.items] }, ...old.pages.slice(1)],
    };
  });
}

function handleBookingStatusEvent(
  qc: ReturnType<typeof useQueryClient>,
  payload: BookingStatusChangedPayload
) {
  const status = mapStatusNameToValue(payload.status);
  patchBookingStatusInCache(qc, payload.bookingId, status, payload.rejectionReason);
}

/**
 * Connects SignalR on login and keeps notifications + booking caches in sync instantly.
 */
export function useNotificationHubSync() {
  const qc = useQueryClient();
  const { isAuthenticated, token } = useAuthStore();
  const { showToast } = useToast();

  useEffect(() => {
    if (!isAuthenticated || !token) {
      void notificationRealtimeService.disconnect();
      return;
    }

    const unsubscribe = notificationRealtimeService.subscribe({
      onNotification: (notification, unreadCount) => {
        if (!shouldProcessEvent(notification.id)) return;

        qc.setQueryData(UNREAD_KEY, unreadCount);
        prependNotification(qc, notification);
        showToast(getNotificationText(notification, 'title'), 'info');

        if (
          notification.relatedEntityId != null &&
          isBookingNotificationType(notification.notificationTypeName)
        ) {
          patchBookingStatusInCache(
            qc,
            notification.relatedEntityId,
            mapStatusNameToValue(notification.notificationTypeName)
          );
        }
      },

      onBookingStatusChanged: (payload) => {
        if (!shouldProcessEvent(payload.id)) return;

        handleBookingStatusEvent(qc, payload);

        const notification = bookingEventToNotification(payload);
        prependNotification(qc, notification);
        qc.setQueryData<number>(UNREAD_KEY, (old) => (old ?? 0) + 1);
        showToast(getNotificationText(notification, 'title'), 'info');
      },
    });

    const onVisibility = () => {
      if (document.visibilityState === 'visible') {
        void notificationRealtimeService.reconnectIfNeeded();
      }
    };
    document.addEventListener('visibilitychange', onVisibility);

    return () => {
      document.removeEventListener('visibilitychange', onVisibility);
      unsubscribe();
    };
  }, [isAuthenticated, token, qc, showToast]);
}

/** Alias for booking-focused screens — same singleton subscription. */
export const useBookingRealtimeSync = useNotificationHubSync;
