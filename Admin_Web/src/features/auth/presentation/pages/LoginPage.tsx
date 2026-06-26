import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../../../core/auth/store';
import { ROUTES } from '../../../../core/constants';
import { Button } from '../../../../shared/ui/Button';
import { LogIn, AlertCircle } from 'lucide-react';
import { AppError } from '../../../../core/errors';

const loginSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const navigate = useNavigate();
  const { login, isAuthenticated, token, initializeAuth } = useAuthStore();
  const [loginError, setLoginError] = useState<string | null>(null);
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  // Initialize auth and check for existing token
  React.useEffect(() => {
    initializeAuth();
    const hasToken = localStorage.getItem('auth_token');
    if (hasToken && (isAuthenticated || token)) {
      navigate(ROUTES.DASHBOARD, { replace: true });
    }
  }, [initializeAuth, isAuthenticated, token, navigate]);

  // Redirect if already authenticated
  if (isAuthenticated || token) {
    return null;
  }

  const onSubmit = async (data: LoginFormData) => {
    setLoginError(null); // Clear previous errors
    try {
      await login({
        username: data.username,
        password: data.password,
        userType: 'Admin',
      });
      navigate(ROUTES.DASHBOARD, { replace: true });
    } catch (error: any) {
      console.error('Login failed:', error);
      
      // Extract error message from various error types
      let errorMessage = 'Wrong username or password';
      
      if (error instanceof AppError) {
        errorMessage = error.message || 'Wrong username or password';
      } else if (error instanceof Error) {
        errorMessage = error.message || 'Wrong username or password';
      } else if (error?.message) {
        errorMessage = error.message;
      }
      
      // Default message if no specific message found
      if (errorMessage === 'Unauthorized' || errorMessage === 'Network error occurred') {
        errorMessage = 'Wrong username or password';
      }
      
      setLoginError(errorMessage);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <div className="text-center mb-8">
            <div className="flex justify-center mb-4">
              <div className="w-16 h-16 bg-blue-600 rounded-lg flex items-center justify-center">
                <LogIn className="w-8 h-8 text-white" />
              </div>
            </div>
            <h2 className="text-2xl font-bold text-gray-900">Welcome Back</h2>
            <p className="text-gray-600 mt-2">Sign in to your admin account</p>
          </div>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            {loginError && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <p className="text-sm font-medium text-red-800">Login Failed</p>
                  <p className="text-sm text-red-600 mt-1">{loginError}</p>
                </div>
              </div>
            )}

            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700 mb-1">
                Username
              </label>
              <input
                {...register('username')}
                type="text"
                id="username"
                autoComplete="username"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Enter your username"
              />
              {errors.username && (
                <p className="mt-1 text-sm text-red-600">{errors.username.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <input
                {...register('password')}
                type="password"
                id="password"
                autoComplete="current-password"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Enter your password"
              />
              {errors.password && (
                <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
              )}
            </div>

            <Button
              type="submit"
              variant="primary"
              className="w-full"
              disabled={isSubmitting}
            >
              {isSubmitting ? (
                <span className="flex items-center justify-center">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  Signing in...
                </span>
              ) : (
                'Sign In'
              )}
            </Button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-xs text-gray-500">
              Enter your username and password to sign in
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
