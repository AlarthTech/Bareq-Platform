import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { authApi } from '../api/auth.api';
import { ROUTES } from '../core/constants';
import { useToast } from '../shared/context/ToastContext';
import { Button } from '../shared/ui/Button';

const schema = z.object({
  fullName: z.string().min(2, 'الاسم مطلوب'),
  phone: z.string().min(8, 'رقم الهاتف مطلوب'),
  email: z.string().email('بريد إلكتروني غير صالح'),
  password: z.string().min(6, '6 أحرف على الأقل'),
});

type FormData = z.infer<typeof schema>;

export default function SetupPage() {
  const navigate = useNavigate();
  const { showToast } = useToast();
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const mutation = useMutation({
    mutationFn: authApi.createAdmin,
    onSuccess: () => {
      showToast('تم إنشاء حساب المدير. يمكنك تسجيل الدخول الآن.', 'success');
      navigate(ROUTES.LOGIN);
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-lg w-full bg-white rounded-2xl shadow-lg p-8">
        <h1 className="text-xl font-bold mb-2">إعداد المدير الأول</h1>
        <p className="text-sm text-gray-500 mb-6">إنشاء حساب مدير المنصة لأول مرة</p>
        <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="space-y-4">
          {(['fullName', 'phone', 'email', 'password'] as const).map((field) => (
            <div key={field}>
              <label className="block text-sm font-medium mb-1">
                {field === 'fullName' ? 'الاسم' : field === 'phone' ? 'الهاتف' : field === 'email' ? 'البريد' : 'كلمة المرور'}
              </label>
              <input
                {...register(field)}
                type={field === 'password' ? 'password' : field === 'email' ? 'email' : 'text'}
                className="w-full px-3 py-2 border rounded-lg"
              />
              {errors[field] && <p className="text-red-600 text-xs mt-1">{errors[field]?.message}</p>}
            </div>
          ))}
          <Button type="submit" disabled={isSubmitting || mutation.isPending} className="w-full">
            إنشاء حساب المدير
          </Button>
        </form>
      </div>
    </div>
  );
}
