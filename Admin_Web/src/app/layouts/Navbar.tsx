import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../core/auth/store';
import { ROUTES } from '../../core/constants';
import { LogOut, User, ChevronDown } from 'lucide-react';
import { Menu, Transition } from '@headlessui/react';
import { Fragment } from 'react';
import { classNames } from '../../core/utils';

interface NavbarProps {
  collapsed: boolean;
}

export const Navbar = ({ collapsed }: NavbarProps) => {
  const navigate = useNavigate();
  const { user, logout } = useAuthStore();

  const handleLogout = () => {
    logout();
    navigate(ROUTES.LOGIN, { replace: true });
  };

  if (!user) {
    return null;
  }

  const userName = user.fullName || 'Admin';
  const userEmail = user.email || '';
  const userInitial = userName.charAt(0).toUpperCase();

  return (
    <header
      className={classNames(
        'bg-white border-b border-gray-200 h-16 fixed top-0 right-0 z-30 sidebar-transition',
        collapsed ? 'left-16' : 'left-64'
      )}
    >
      <div className="flex items-center justify-end h-full px-6">
        <Menu as="div" className="relative">
          <Menu.Button className="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50">
            <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center text-white text-sm font-medium">
              {userInitial}
            </div>
            <div className="text-left hidden md:block">
              <p className="text-sm font-medium text-gray-900">{userName}</p>
              <p className="text-xs text-gray-500">{userEmail}</p>
            </div>
            <ChevronDown className="w-4 h-4 text-gray-500 hidden md:block" />
          </Menu.Button>

          <Transition
            as={Fragment}
            enter="transition ease-out duration-100"
            enterFrom="transform opacity-0 scale-95"
            enterTo="transform opacity-100 scale-100"
            leave="transition ease-in duration-75"
            leaveFrom="transform opacity-100 scale-100"
            leaveTo="transform opacity-0 scale-95"
          >
            <Menu.Items className="absolute right-0 mt-2 w-56 origin-top-right divide-y divide-gray-100 rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none">
              <div className="px-1 py-1">
                <Menu.Item>
                  {({ active }) => (
                    <button
                      className={`${
                        active ? 'bg-gray-100' : ''
                      } group flex w-full items-center gap-2 rounded-md px-2 py-2 text-sm text-gray-900`}
                    >
                      <User className="w-4 h-4" />
                      Profile
                    </button>
                  )}
                </Menu.Item>
              </div>
              <div className="px-1 py-1">
                <Menu.Item>
                  {({ active }) => (
                    <button
                      onClick={handleLogout}
                      className={`${
                        active ? 'bg-gray-100' : ''
                      } group flex w-full items-center gap-2 rounded-md px-2 py-2 text-sm text-red-600`}
                    >
                      <LogOut className="w-4 h-4" />
                      Logout
                    </button>
                  )}
                </Menu.Item>
              </div>
            </Menu.Items>
          </Transition>
        </Menu>
      </div>
    </header>
  );
};
