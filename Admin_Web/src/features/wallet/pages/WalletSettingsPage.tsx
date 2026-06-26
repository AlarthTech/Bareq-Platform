import { Link } from 'react-router-dom';
import { ROUTES } from '../../../core/constants';
import { PageHeader } from '../../../shared/components/PageHeader';
import { WalletSettingsForm } from '../components/WalletSettingsForm';

export default function WalletSettingsPage() {
  return (
    <div className="max-w-xl space-y-6">
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <Link to={ROUTES.SETTINGS} className="hover:text-bareq-600">
          الإعدادات
        </Link>
        <span>/</span>
        <span>إعدادات المحفظة</span>
      </div>

      <PageHeader
        title="إعدادات المحفظة"
        subtitle="تفعيل الدفع بالمحفظة ونسبة الرسوم على الحجوزات الجديدة"
      />

      <div className="flex flex-wrap gap-3 text-sm">
        <Link
          to={ROUTES.WALLET_BANK_ACCOUNTS}
          className="text-bareq-600 hover:underline"
        >
          حسابات التحويل البنكي
        </Link>
        <span className="text-gray-300">|</span>
        <Link to={ROUTES.WALLET_TOP_UPS} className="text-bareq-600 hover:underline">
          طلبات شحن المحفظة
        </Link>
        <span className="text-gray-300">|</span>
        <Link to={ROUTES.WALLET_MANUAL_CREDIT} className="text-bareq-600 hover:underline">
          شحن يدوي
        </Link>
      </div>

      <p className="text-sm text-gray-600 bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
        شحن البطاقة يتم تلقائياً عبر بوابة الدفع. راجع تبويب «بطاقة بنكية» في طلبات الشحن
        للتأكيد اليدوي عند الحاجة.
      </p>

      <WalletSettingsForm />
    </div>
  );
}
