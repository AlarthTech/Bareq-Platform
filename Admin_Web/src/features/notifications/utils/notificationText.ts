import type { NotificationDateGroup, NotificationDTO } from '../types';

function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function getDateGroup(createdAt: string): NotificationDateGroup {
  const date = new Date(createdAt);
  const now = new Date();
  const today = startOfDay(now);
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const itemDay = startOfDay(date);

  if (itemDay.getTime() === today.getTime()) return 'today';
  if (itemDay.getTime() === yesterday.getTime()) return 'yesterday';
  return 'earlier';
}

export function groupNotificationsByDate(
  notifications: NotificationDTO[]
): { group: NotificationDateGroup; items: NotificationDTO[] }[] {
  const groups: Record<NotificationDateGroup, NotificationDTO[]> = {
    today: [],
    yesterday: [],
    earlier: [],
  };

  for (const n of notifications) {
    groups[getDateGroup(n.createdAt)].push(n);
  }

  return (['today', 'yesterday', 'earlier'] as const)
    .filter((g) => groups[g].length > 0)
    .map((g) => ({ group: g, items: groups[g] }));
}

export function formatRelativeTime(createdAt: string, locale = 'ar'): string {
  const date = new Date(createdAt);
  const now = Date.now();
  const diffSec = Math.round((date.getTime() - now) / 1000);
  const abs = Math.abs(diffSec);

  const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });

  if (abs < 60) return rtf.format(diffSec, 'second');
  if (abs < 3600) return rtf.format(Math.round(diffSec / 60), 'minute');
  if (abs < 86400) return rtf.format(Math.round(diffSec / 3600), 'hour');
  if (abs < 604800) return rtf.format(Math.round(diffSec / 86400), 'day');
  return date.toLocaleDateString(locale === 'ar' ? 'ar-LY' : 'en-US', {
    month: 'short',
    day: 'numeric',
    timeZone: 'Africa/Tripoli',
  });
}

export function isArabicLocale(): boolean {
  return document.documentElement.lang === 'ar' || document.documentElement.dir === 'rtl';
}

export function getNotificationText(
  notification: NotificationDTO,
  field: 'title' | 'message'
): string {
  const ar = field === 'title' ? notification.titleAr : notification.messageAr;
  const en = field === 'title' ? notification.title : notification.message;
  return isArabicLocale() ? ar || en : en || ar;
}
