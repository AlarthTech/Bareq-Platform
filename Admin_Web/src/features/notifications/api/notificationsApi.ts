import { apiClient } from '../../../core/api/client';
import type { PagedResult } from '../../../types/api.types';
import type { NotificationDTO } from '../types';

export const notificationsApi = {
  getMyNotifications: (page = 1, pageSize = 20) =>
    apiClient.get<PagedResult<NotificationDTO>>('/Notifications/GetMyNotifications', {
      page,
      pageSize,
    }),

  getUnreadCount: () =>
    apiClient.get<number>('/Notifications/GetUnreadCount'),

  markAsRead: (id: number) =>
    apiClient.patch<void>(`/Notifications/MarkAsRead/${id}`),

  markAllAsRead: () =>
    apiClient.patch<void>('/Notifications/MarkAllAsRead'),

  deleteNotification: (id: number) =>
    apiClient.delete<void>(`/Notifications/DeleteNotification/${id}`),
};
