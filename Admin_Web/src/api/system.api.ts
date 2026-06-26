import { apiClient } from '../core/api/client';

export const systemApi = {
  testEmail: (data: { toEmail: string; template?: string }) =>
    apiClient.post<{ success: boolean; message: string }>('/AppUsers/TestEmail', data),
};
