import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useNavigate } from 'react-router-dom';
import { LogIn, AlertCircle } from 'lucide-react';
import { useAuthStore, hasValidToken } from '../core/auth/store';
import { clearAuthSession } from '../core/auth/clearSession';
import { useAuthHydrated } from '../core/auth/useAuthHydrated';
import { ROUTES } from '../core/constants';
import { Button } from '../shared/ui/Button';
import { ValidationError } from '../core/errors';

const schema = z.object({
  username: z.string().min(1, 'أدخل البريد أو الهاتف'),
  password: z.string().min(1, 'أدخل كلمة المرور'),
});

type FormData = z.infer<typeof schema>;

function formatLoginError(err: unknown): string {
  if (err instanceof ValidationError) {
    return err.message;
  }
  if (err instanceof Error) {
    return err.message;
  }
  return 'فشل تسجيل الدخول';
}

export default function LoginPage() {
  const navigate = useNavigate();
  const hydrated = useAuthHydrated();
  const { login, isAuthenticated, initializeAuth } = useAuthStore();
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { isSubmitting },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  useEffect(() => {
    if (!hydrated) return;

    if (!hasValidToken()) {
      clearAuthSession();
      useAuthStore.setState({ user: null, token: null, isAuthenticated: false });
    } else {
      initializeAuth();
    }
  }, [hydrated, initializeAuth]);

  useEffect(() => {
    if (!hydrated) return;
    if (hasValidToken() && isAuthenticated) {
      navigate(ROUTES.DASHBOARD, { replace: true });
    }
  }, [hydrated, isAuthenticated, navigate]);

  const onSubmit = async (data: FormData) => {
    setError(null);
    try {
      await login({
        username: data.username.trim(),
        password: data.password,
        userType: 'Admin',
      });
      navigate(ROUTES.DASHBOARD, { replace: true });
    } catch (e) {
      const msg = formatLoginError(e);
      if (msg.includes('403') || msg.includes('Forbidden')) {
        navigate(ROUTES.SETUP);
        return;
      }
      setError(msg);
    }
  };

  if (!hydrated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-bareq-50 to-gray-100">
        <div className="animate-spin w-8 h-8 border-2 border-bareq-600 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-bareq-50 to-gray-100 px-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8">
        <div className="text-center mb-8">
          <div className="inline-flex w-16 h-16 bg-bareq-600 rounded-2xl items-center justify-center mb-4">
            <LogIn className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">برق — لوحة الإدارة</h1>
          <p className="text-gray-500 mt-2 text-sm">تسجيل الدخول بحساب المدير</p>
        </div>

        {error && (
          <div
            className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg flex gap-2 text-sm text-red-700 max-h-40 overflow-y-auto"
            role="alert"
          >
            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
            <div className="min-w-0 break-words whitespace-pre-wrap">{error}</div>
          </div>
        )}

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">البريد أو الهاتف</label>
            <input
              {...register('username')}
              className="w-full px-4 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-bareq-500 focus:border-transparent"
              autoComplete="username"
              disabled={isSubmitting}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">كلمة المرور</label>
            <input
              {...register('password')}
              type="password"
              className="w-full px-4 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-bareq-500 focus:border-transparent"
              autoComplete="current-password"
              disabled={isSubmitting}
            />
          </div>
          <Button
            type="submit"
            variant="primary"
            className="w-full !bg-bareq-600 hover:!bg-bareq-700"
            disabled={isSubmitting}
          >
            {isSubmitting ? 'جاري الدخول...' : 'تسجيل الدخول'}
          </Button>
        </form>
      </div>
    </div>
  );
}
