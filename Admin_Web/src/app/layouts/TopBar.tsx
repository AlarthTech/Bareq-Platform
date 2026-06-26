import { Fragment } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../core/auth/store';
import { ROUTES } from '../../core/constants';
import { LogOut, User, ChevronDown, Menu } from 'lucide-react';
import { Menu as HeadlessMenu, Transition } from '@headlessui/react';
import { classNames } from '../../core/utils';
import { NotificationBell } from '../../features/notifications/components/NotificationBell';

interface TopBarProps {
  collapsed: boolean;
  onMenuClick?: () => void;
}

export function TopBar({ collapsed, onMenuClick }: TopBarProps) {
  const navigate = useNavigate();
  const { user, logout } = useAuthStore();

  if (!user) return null;

  const initial = user.fullName.charAt(0);

  return (
    <header
      className={classNames(
        'bg-white border-b border-gray-200 h-16 fixed top-0 left-0 z-30 sidebar-transition max-md:right-0',
        collapsed ? 'md:right-16' : 'md:right-64'
      )}
    >
      <div className="flex items-center justify-between h-full px-4 md:px-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onMenuClick}
            className="p-2 rounded-lg hover:bg-gray-100 md:hidden"
            aria-label="فتح القائمة"
          >
            <Menu className="w-5 h-5 text-gray-600" />
          </button>
          <h2 className="text-sm text-gray-500 hidden sm:block">CleaningHouse / Bareq</h2>
        </div>

        <div className="flex items-center gap-2">
          <NotificationBell />

          <HeadlessMenu as="div" className="relative">
            <HeadlessMenu.Button className="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50">
              <div className="w-9 h-9 bg-bareq-600 rounded-full flex items-center justify-center text-white text-sm font-bold">
                {initial}
              </div>
              <div className="text-right hidden md:block">
                <p className="text-sm font-medium text-gray-900">{user.fullName}</p>
                <p className="text-xs text-gray-500">{user.email || user.phone}</p>
              </div>
              <ChevronDown className="w-4 h-4 text-gray-500 hidden md:block" />
            </HeadlessMenu.Button>
            <Transition
              as={Fragment}
              enter="transition ease-out duration-100"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="transition ease-in duration-75"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <HeadlessMenu.Items className="absolute left-0 mt-2 w-52 rounded-xl bg-white shadow-lg ring-1 ring-black/5 focus:outline-none overflow-hidden">
                <HeadlessMenu.Item>
                  {({ active }) => (
                    <button
                      type="button"
                      onClick={() => navigate(ROUTES.SETTINGS)}
                      className={classNames(
                        'flex w-full items-center gap-2 px-4 py-2.5 text-sm',
                        active ? 'bg-gray-50' : ''
                      )}
                    >
                      <User className="w-4 h-4" />
                      الملف الشخصي
                    </button>
                  )}
                </HeadlessMenu.Item>
                <HeadlessMenu.Item>
                  {({ active }) => (
                    <button
                      type="button"
                      onClick={() => {
                        logout();
                        navigate(ROUTES.LOGIN, { replace: true });
                      }}
                      className={classNames(
                        'flex w-full items-center gap-2 px-4 py-2.5 text-sm text-red-600',
                        active ? 'bg-red-50' : ''
                      )}
                    >
                      <LogOut className="w-4 h-4" />
                      تسجيل الخروج
                    </button>
                  )}
                </HeadlessMenu.Item>
              </HeadlessMenu.Items>
            </Transition>
          </HeadlessMenu>
        </div>
      </div>
    </header>
  );
}
