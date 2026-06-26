export const config = {
  apiBaseUrl: import.meta.env.VITE_API_URL
    ? `${import.meta.env.VITE_API_URL}/api`
    : '/api',
  appName: import.meta.env.VITE_APP_NAME || 'Bareq Admin Dashboard',
} as const;

/** SignalR hub via same-origin proxy (/hubs in dev and production). */
export function getHubUrl(): string {
  return `${window.location.origin}/hubs/notifications`;
}
