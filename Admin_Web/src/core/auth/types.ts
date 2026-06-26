import type { AppUser } from '../../types/api.types';

export interface AuthState {
  user: AppUser | null;
  token: string | null;
  isAuthenticated: boolean;
}

export interface LoginCredentials {
  username: string;
  password: string;
  userType: 'Admin';
}

export interface LoginResult {
  user: AppUser;
  token: string;
}
