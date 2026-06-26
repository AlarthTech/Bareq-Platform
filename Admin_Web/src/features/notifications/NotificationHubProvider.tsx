import { useNotificationHubSync } from './hooks/useRealtimeSync';

/** Connects SignalR hub while admin is authenticated. Renders nothing. */
export function NotificationHubProvider() {
  useNotificationHubSync();
  return null;
}
