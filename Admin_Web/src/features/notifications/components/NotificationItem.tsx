import { classNames } from '../../../core/utils';
import type { NotificationDTO } from '../types';
import {
  formatRelativeTime,
  getNotificationText,
} from '../utils/notificationText';

interface NotificationItemProps {
  notification: NotificationDTO;
  onClick: () => void;
}

export function NotificationItem({ notification, onClick }: NotificationItemProps) {
  const title = getNotificationText(notification, 'title');
  const message = getNotificationText(notification, 'message');

  return (
    <button
      type="button"
      onClick={onClick}
      className={classNames(
        'w-full text-right px-4 py-3 hover:bg-gray-50 transition-colors border-b border-gray-100 last:border-0',
        !notification.isRead && 'bg-bareq-50/40'
      )}
    >
      <div className="flex items-start gap-2">
        {!notification.isRead && (
          <span className="mt-2 w-2 h-2 rounded-full bg-bareq-600 shrink-0" aria-hidden />
        )}
        <div className={classNames('flex-1 min-w-0', notification.isRead && 'mr-4')}>
          <p
            className={classNames(
              'text-sm text-gray-900 line-clamp-1',
              !notification.isRead && 'font-semibold'
            )}
          >
            {title}
          </p>
          <p className="text-xs text-gray-500 mt-0.5 line-clamp-2">{message}</p>
          <p className="text-xs text-gray-400 mt-1">{formatRelativeTime(notification.createdAt)}</p>
        </div>
      </div>
    </button>
  );
}
