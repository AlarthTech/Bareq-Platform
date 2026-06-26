import { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuthStore, hasValidToken } from '../../core/auth/store';
import { isAdminRole } from '../../core/auth/isAdminRole';
import { ROUTES } from '../../core/constants';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, token, user, initializeAuth } = useAuthStore();
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    initializeAuth();
    setChecking(false);
  }, [initializeAuth]);

  if (checking) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-bareq-600 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!hasValidToken() || (!isAuthenticated && !token)) {
    return <Navigate to={ROUTES.LOGIN} replace />;
  }

  if (user && !isAdminRole(user.userTypeName)) {
    return <Navigate to={ROUTES.LOGIN} replace />;
  }

  return <>{children}</>;
}
