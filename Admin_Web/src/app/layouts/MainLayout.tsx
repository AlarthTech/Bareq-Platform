import { useState, useCallback } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { TopBar } from './TopBar';
import { classNames } from '../../core/utils';

import { NotificationHubProvider } from '../../features/notifications/NotificationHubProvider';

const SIDEBAR_COLLAPSED_KEY = 'bareq.sidebar.collapsed';

function readCollapsed(): boolean {
  try {
    return localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === 'true';
  } catch {
    return false;
  }
}

export function MainLayout() {
  const [collapsed, setCollapsedState] = useState(readCollapsed);
  const [mobileOpen, setMobileOpen] = useState(false);

  const setCollapsed = useCallback((value: boolean) => {
    setCollapsedState(value);
    try {
      localStorage.setItem(SIDEBAR_COLLAPSED_KEY, String(value));
    } catch {
      // ignore storage errors
    }
  }, []);

  const closeMobile = useCallback(() => setMobileOpen(false), []);

  return (
    <div className="flex h-screen bg-gray-50">
      <NotificationHubProvider />
      <Sidebar
        collapsed={collapsed}
        setCollapsed={setCollapsed}
        mobileOpen={mobileOpen}
        onMobileClose={closeMobile}
      />
      <div
        className={classNames(
          'flex-1 flex flex-col sidebar-transition max-md:mr-0',
          collapsed ? 'md:mr-16' : 'md:mr-64'
        )}
      >
        <TopBar
          collapsed={collapsed}
          onMenuClick={() => setMobileOpen(true)}
        />
        <main className="flex-1 overflow-y-auto p-4 md:p-6 mt-16">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
