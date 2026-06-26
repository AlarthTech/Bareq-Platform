import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation } from '@tanstack/react-query';
import { systemApi } from '../../api/system.api';
import { PageHeader } from '../../shared/components/PageHeader';
import { useToast } from '../../shared/context/ToastContext';
import { Button } from '../../shared/ui/Button';

const schema = z.object({
  toEmail: z.string().email('بريد غير صالح'),
  template: z.string().optional(),
});

type FormData = z.infer<typeof schema>;

const TEMPLATES = [
  { value: '', label: 'اختبار SMTP عادي' },
  { value: 'welcome', label: 'ترحيب' },
  { value: 'password-reset-otp', label: 'OTP إعادة تعيين (عميل)' },
  { value: 'company-password-reset-otp', label: 'OTP إعادة تعيين (شركة)' },
  { value: 'password-changed', label: 'تم تغيير كلمة المرور' },
  { value: 'auto-reply', label: 'رد تلقائي' },
];

export default function EmailTestPage() {
  const { showToast } = useToast();
  const { register, handleSubmit, formState: { isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const mutation = useMutation({
    mutationFn: (data: FormData) =>
      systemApi.testEmail({
        toEmail: data.toEmail,
        template: data.template || undefined,
      }),
    onSuccess: (r) => showToast(r.message || (r.success ? 'تم الإرسال' : 'فشل الإرسال'), r.success ? 'success' : 'error'),
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div className="max-w-lg">
      <PageHeader title="اختبار البريد" subtitle="تشخيص SMTP" />
      <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="bg-white rounded-xl border p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">البريد المستلم</label>
          <input {...register('toEmail')} type="email" className="w-full border rounded-lg px-3 py-2" placeholder="you@gmail.com" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">القالب</label>
          <select {...register('template')} className="w-full border rounded-lg px-3 py-2">
            {TEMPLATES.map((t) => (
              <option key={t.value} value={t.value}>{t.label}</option>
            ))}
          </select>
        </div>
        <Button type="submit" disabled={isSubmitting || mutation.isPending} className="w-full">
          إرسال بريد تجريبي
        </Button>
      </form>
    </div>
  );
}
