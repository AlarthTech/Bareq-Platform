import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { AppUser } from '../../types/api.types';
import type { AuthState, LoginCredentials } from './types';
import { authApi } from '../../api/auth.api';
import { TOKEN_KEY } from '../constants';
import { clearAuthSession } from './clearSession';
import { isAdminRole } from './isAdminRole';

interface AuthStore extends AuthState {
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => void;
  setUser: (user: AppUser) => void;
  initializeAuth: () => void;
  isAdmin: () => boolean;
}

function hasValidToken(): boolean {
  const token = localStorage.getItem(TOKEN_KEY);
  if (!token) return false;
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return false;
    const payload = JSON.parse(atob(parts[1]));
    if (payload.exp && payload.exp < Date.now() / 1000) return false;
    return true;
  } catch {
    return false;
  }
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,

      initializeAuth: () => {
        const token = localStorage.getItem(TOKEN_KEY);
        if (token && hasValidToken()) {
          const stored = localStorage.getItem('auth-storage');
          if (stored) {
            try {
              const parsed = JSON.parse(stored);
              if (parsed.state?.user && parsed.state?.token) {
                set({
                  user: parsed.state.user,
                  token: parsed.state.token,
                  isAuthenticated: true,
                });
                return;
              }
            } catch {
              /* ignore */
            }
          }
        }
        set({ user: null, token: null, isAuthenticated: false });
      },

      login: async (credentials) => {
        const response = await authApi.login(credentials);
        if (!isAdminRole(response.user.userTypeName)) {
          localStorage.removeItem(TOKEN_KEY);
          throw new Error('لا تملك صلاحية — حساب المدير فقط');
        }
        localStorage.setItem(TOKEN_KEY, response.token);
        localStorage.removeItem('auth_token');
        set({ user: response.user, token: response.token, isAuthenticated: true });
      },

      logout: () => {
        clearAuthSession();
        set({ user: null, token: null, isAuthenticated: false });
      },

      setUser: (user) => set({ user, isAuthenticated: true }),

      isAdmin: () => isAdminRole(get().user?.userTypeName),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);

export { hasValidToken };
