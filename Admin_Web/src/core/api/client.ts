import axios, { AxiosError } from 'axios';
import type { AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import { config } from '../config/env';
import { TOKEN_KEY } from '../constants';
import { clearAuthSession } from '../auth/clearSession';
import { AppError, NetworkError, UnauthorizedError, ValidationError } from '../errors';

type ToastHandler = (message: string, type: 'error' | 'success' | 'info') => void;
let toastHandler: ToastHandler | null = null;

export function setApiToastHandler(handler: ToastHandler) {
  toastHandler = handler;
}

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: config.apiBaseUrl,
      headers: { 'Content-Type': 'application/json' },
      timeout: 30000,
    });
    this.setupInterceptors();
  }

  private setupInterceptors(): void {
    this.client.interceptors.request.use(
      (cfg: InternalAxiosRequestConfig) => {
        const isLoginRequest = cfg.url?.includes('/AppUsers/Login') ?? false;
        const token = localStorage.getItem(TOKEN_KEY) ?? localStorage.getItem('auth_token');
        if (token && cfg.headers && !isLoginRequest) {
          cfg.headers.Authorization = `Bearer ${token}`;
        }
        return cfg;
      },
      (error) => Promise.reject(error)
    );

    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError<{ message?: string; detail?: string; title?: string; errors?: Record<string, string[]> }>) => {
        if (!error.response) {
          return Promise.reject(new NetworkError('خطأ في الاتصال بالشبكة'));
        }

        const { status, data } = error.response;
        const message =
          data?.message?.trim() ||
          data?.detail?.trim() ||
          data?.title?.trim() ||
          'حدث خطأ غير متوقع';

        switch (status) {
          case 401: {
            const requestUrl = error.config?.url ?? '';
            const isLoginRequest = requestUrl.includes('/AppUsers/Login');
            const onLoginPage =
              window.location.pathname === '/login' ||
              window.location.pathname.endsWith('/login');

            if (!isLoginRequest) {
              clearAuthSession();
              if (!onLoginPage) {
                window.location.assign('/login');
              }
            }

            const loginMessage = isLoginRequest
              ? 'بيانات الدخول غير صحيحة'
              : message;
            return Promise.reject(new UnauthorizedError(loginMessage));
          }
          case 403:
            toastHandler?.('لا تملك صلاحية', 'error');
            return Promise.reject(new AppError(message, 403));
          case 400:
            return Promise.reject(new ValidationError(message, data?.errors));
          case 404:
            return Promise.reject(new AppError('غير موجود', 404));
          case 409:
            return Promise.reject(new AppError(message, 409));
          case 429:
            toastHandler?.('تم تجاوز الحد المسموح. يرجى المحاولة لاحقاً', 'error');
            return Promise.reject(new AppError(message, 429));
          default:
            return Promise.reject(new AppError(message, status));
        }
      }
    );
  }

  async get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
    const response = await this.client.get<T>(url, { params });
    return response.data;
  }

  async post<T>(url: string, data?: unknown, cfg?: Record<string, unknown>): Promise<T> {
    const response = await this.client.post<T>(url, data, cfg);
    return response.data;
  }

  async put<T>(url: string, data?: unknown, cfg?: Record<string, unknown>): Promise<T> {
    const response = await this.client.put<T>(url, data, cfg);
    return response.data;
  }

  async patch<T>(url: string, data?: unknown, cfg?: Record<string, unknown>): Promise<T> {
    const response = await this.client.patch<T>(url, data, cfg);
    return response.data;
  }

  async delete<T>(url: string): Promise<T> {
    const response = await this.client.delete<T>(url);
    return response.data;
  }

  async upload<T>(url: string, file: File, fieldName = 'file'): Promise<T> {
    const formData = new FormData();
    formData.append(fieldName, file);
    const response = await this.client.post<T>(url, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return response.data;
  }
}

export const apiClient = new ApiClient();
