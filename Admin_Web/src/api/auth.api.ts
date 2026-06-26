import { apiClient } from '../core/api/client';
import type { LoginCredentials, LoginResult } from '../core/auth/types';
import type { LoginResponse } from '../types/api.types';

export const authApi = {
  login: async (credentials: LoginCredentials): Promise<LoginResult> => {
    const response = await apiClient.post<LoginResponse>('/AppUsers/Login', {
      username: credentials.username,
      password: credentials.password,
      userType: 'Admin',
    });
    if (!response.success || !response.token) {
      throw new Error(response.message || 'فشل تسجيل الدخول');
    }
    return { user: response.user, token: response.token };
  },

  createAdmin: (data: {
    fullName: string;
    phone: string;
    email: string;
    password: string;
    cityId?: number;
  }) => apiClient.post('/AppUsers/CreateNewAdmin', data),

  changePassword: (data: { currentPassword: string; newPassword: string }) =>
    apiClient.put('/AppUsers/ChangePassword', data),

  changePersonalInfo: (data: { fullName: string; email: string }) =>
    apiClient.put('/AppUsers/ChangePersonalInfo', data),

  changePhoneNumber: (data: { phone: string }) =>
    apiClient.put('/AppUsers/ChangePhoneNumber', data),
};
