import { Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation } from '@tanstack/react-query';
import {
  Wallet,
  CircleDollarSign,
  Landmark,
  Banknote,
  Coins,
} from 'lucide-react';
import { authApi } from '../../api/auth.api';
import { useAuthStore } from '../../core/auth/store';
import { ROUTES } from '../../core/constants';
import { PageHeader } from '../../shared/components/PageHeader';
import { useToast } from '../../shared/context/ToastContext';
import { Button } from '../../shared/ui/Button';
import { usePlatformFee } from '../../features/platform-fee/hooks/usePlatformFee';
import { formatLyd } from '../../core/utils';

const passwordSchema = z
  .object({
    currentPassword: z.string().min(1),
    newPassword: z.string().min(6),
    confirm: z.string(),
  })
  .refine((d) => d.newPassword === d.confirm, { message: 'كلمات المرور غير متطابقة', path: ['confirm'] });

const profileSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(8),
});

const financeLinks = [
  { to: ROUTES.PLATFORM_FEE, title: 'رسوم المنصة', desc: 'عمولة ثابتة على الحجز', icon: CircleDollarSign },
  { to: ROUTES.WALLET_SETTINGS, title: 'إعدادات المحفظة', desc: 'تفعيل الدفع بالمحفظة ونسبة الرسوم', icon: Wallet },
  { to: ROUTES.WALLET_TOP_UPS, title: 'طلبات شحن المحفظة', desc: 'تحويل بنكي وبطاقة', icon: Banknote },
  { to: ROUTES.WALLET_BANK_ACCOUNTS, title: 'حسابات التحويل البنكي', desc: 'إدارة حسابات استلام التحويل', icon: Landmark },
  { to: ROUTES.WALLET_MANUAL_CREDIT, title: 'شحن محفظة يدوي', desc: 'إضافة رصيد لعميل أو مجموعة', icon: Coins },
];

export default function SettingsPage() {
  const { user, setUser } = useAuthStore();
  const { showToast } = useToast();
  const { data: platformFee } = usePlatformFee();

  const passwordForm = useForm({ resolver: zodResolver(passwordSchema) });
  const profileForm = useForm({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      fullName: user?.fullName ?? '',
      email: user?.email ?? '',
      phone: user?.phone ?? '',
    },
  });

  const changePassword = useMutation({
    mutationFn: authApi.changePassword,
    onSuccess: () => {
      showToast('تم تغيير كلمة المرور', 'success');
      passwordForm.reset();
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  const changeProfile = useMutation({
    mutationFn: async (data: z.infer<typeof profileSchema>) => {
      await authApi.changePersonalInfo({ fullName: data.fullName, email: data.email });
      await authApi.changePhoneNumber({ phone: data.phone });
    },
    onSuccess: (_, data) => {
      if (user) {
        setUser({ ...user, fullName: data.fullName, email: data.email, phone: data.phone });
      }
      showToast('تم تحديث البيانات', 'success');
    },
    onError: (e: Error) => showToast(e.message, 'error'),
  });

  return (
    <div className="w-full space-y-8">
      <PageHeader title="الإعدادات" subtitle="الملف الشخصي والمالية" />

      <div>
        <h3 className="text-sm font-semibold text-gray-500 mb-3">المالية</h3>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          {financeLinks.map((link) => {
            const Icon = link.icon;
            const subtitle =
              link.to === ROUTES.PLATFORM_FEE && platformFee != null
                ? `الرسوم الحالية: ${formatLyd(platformFee.fixedPlatformFeeAmount)}`
                : link.desc;
            return (
              <Link
                key={link.to}
                to={link.to}
                className="flex items-center gap-4 bg-white rounded-xl border p-5 hover:border-bareq-300 transition-colors"
              >
                <div className="w-10 h-10 rounded-lg bg-bareq-50 flex items-center justify-center shrink-0">
                  <Icon className="w-5 h-5 text-bareq-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-gray-900">{link.title}</p>
                  <p className="text-sm text-gray-500">{subtitle}</p>
                </div>
              </Link>
            );
          })}
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
      <section className="bg-white rounded-xl border p-6">
        <h3 className="font-semibold mb-4">البيانات الشخصية</h3>
        <form onSubmit={profileForm.handleSubmit((d) => changeProfile.mutate(d))} className="space-y-3">
          <input {...profileForm.register('fullName')} placeholder="الاسم" className="w-full border rounded-lg px-3 py-2" />
          <input {...profileForm.register('email')} placeholder="البريد" className="w-full border rounded-lg px-3 py-2" />
          <input {...profileForm.register('phone')} placeholder="الهاتف" className="w-full border rounded-lg px-3 py-2" />
          <Button type="submit" disabled={changeProfile.isPending}>حفظ</Button>
        </form>
      </section>

      <section className="bg-white rounded-xl border p-6">
        <h3 className="font-semibold mb-4">تغيير كلمة المرور</h3>
        <form
          onSubmit={passwordForm.handleSubmit(({ currentPassword, newPassword }) =>
            changePassword.mutate({ currentPassword, newPassword })
          )}
          className="space-y-3"
        >
          <input {...passwordForm.register('currentPassword')} type="password" placeholder="كلمة المرور الحالية" className="w-full border rounded-lg px-3 py-2" />
          <input {...passwordForm.register('newPassword')} type="password" placeholder="كلمة المرور الجديدة" className="w-full border rounded-lg px-3 py-2" />
          <input {...passwordForm.register('confirm')} type="password" placeholder="تأكيد كلمة المرور" className="w-full border rounded-lg px-3 py-2" />
          <Button type="submit" disabled={changePassword.isPending}>تغيير كلمة المرور</Button>
        </form>
      </section>
      </div>
    </div>
  );
}
