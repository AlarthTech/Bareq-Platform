import { useEffect, useRef, useState } from 'react';
import { Bell } from 'lucide-react';
import { classNames } from '../../../core/utils';
import { NotificationDropdown } from './NotificationDropdown';
import {
  useUnreadCount,
  useHubConnectionState,
  useNewNotificationPulse,
} from '../hooks/useNotifications';

function formatBadge(count: number): string {
  if (count > 99) return '99+';
  return String(count);
}

export function NotificationBell() {
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const hubState = useHubConnectionState();
  const hubConnected = hubState === 'connected';

  const { data: unreadCount = 0 } = useUnreadCount(hubConnected);
  const badgePulse = useNewNotificationPulse(unreadCount);

  useEffect(() => {
    if (!open) return;

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
    };

    const onPointerDown = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };

    document.addEventListener('keydown', onKeyDown);
    document.addEventListener('mousedown', onPointerDown);
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      document.removeEventListener('mousedown', onPointerDown);
    };
  }, [open]);

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-label="Notifications"
        aria-expanded={open}
        className={classNames(
          'relative p-2 rounded-lg transition-colors',
          open ? 'bg-bareq-50 text-bareq-700' : 'text-gray-600 hover:bg-gray-50'
        )}
      >
        <Bell className={classNames('w-5 h-5', badgePulse && 'animate-bell-ring')} />
        {unreadCount > 0 && (
          <span
            className={classNames(
              'absolute -top-0.5 -left-0.5 min-w-[1.125rem] h-[1.125rem] px-1 flex items-center justify-center rounded-full bg-red-600 text-white text-[10px] font-bold leading-none',
              badgePulse && 'animate-badge-pop'
            )}
          >
            {formatBadge(unreadCount)}
          </span>
        )}
        {hubState === 'connected' && (
          <span
            className="absolute bottom-1 right-1 w-1.5 h-1.5 rounded-full bg-green-500 ring-2 ring-white"
            aria-hidden
            title="متصل — تحديثات فورية"
          />
        )}
      </button>

      {open && <NotificationDropdown open={open} onClose={() => setOpen(false)} />}
    </div>
  );
}
