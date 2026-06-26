import { Link } from 'react-router-dom';
import { ROUTES } from '../../../core/constants';
import { PageHeader } from '../../../shared/components/PageHeader';
import { PlatformFeeForm } from '../components/PlatformFeeForm';

export default function PlatformFeeSettingsPage() {
  return (
    <div className="max-w-xl space-y-6">
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <Link to={ROUTES.SETTINGS} className="hover:text-bareq-600">
          الإعدادات
        </Link>
        <span>/</span>
        <span>رسوم المنصة</span>
      </div>

      <PageHeader
        title="رسوم المنصة"
        subtitle="إدارة العمولة الثابتة المضافة على كل حجز جديد"
      />

      <PlatformFeeForm />
    </div>
  );
}
