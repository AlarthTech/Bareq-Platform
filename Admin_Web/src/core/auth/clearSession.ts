import { TOKEN_KEY } from '../constants';

/** Clears JWT and persisted auth state (used on logout and 401). */
export function clearAuthSession(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem('auth_token');
  localStorage.removeItem('auth-storage');
}
