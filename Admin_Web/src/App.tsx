import { useEffect } from 'react';
import { RouterProvider } from 'react-router-dom';
import { AppProviders } from './app/providers/AppProviders';
import { router } from './app/router';
import { ErrorBoundary } from './shared/components/ErrorBoundary';
import { useAuthStore } from './core/auth/store';

function AppContent() {
  const { initializeAuth } = useAuthStore();

  useEffect(() => {
    // Initialize auth when app loads
    initializeAuth();
  }, [initializeAuth]);

  return <RouterProvider router={router} />;
}

function App() {
  return (
    <ErrorBoundary>
      <AppProviders>
        <AppContent />
      </AppProviders>
    </ErrorBoundary>
  );
}

export default App;
