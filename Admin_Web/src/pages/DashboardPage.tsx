import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Building2,
  UserCircle,
  Calendar,
  UserCog,
  Flag,
  CalendarClock,
  Coins,
  Banknote,
  Wallet,
  HandCoins,
  Sigma,
} from 'lucide-react';
import { COMPANY_COMMISSION_PER_BOOKING_LYD } from '../core/constants';
import { companiesApi } from '../api/companies.api';
import { bookingsApi } from '../api/bookings.api';
import { workersApi } from '../api/workers.api';
import { reportsApi } from '../api/reports.api';
import { useOpenBookingReportsCount } from '../hooks/useBookingReports';
import { ROUTES } from '../core/constants';
import { PageHeader } from '../shared/components/PageHeader';
import { KPICard } from '../shared/components/KPICard';
import { Loader } from '../shared/components/Loader';
import { useBookingFinancialStats } from '../hooks/useBookingFinancialStats';
import { useCustomerCount } from '../hooks/useCustomerCount';
import { formatLyd } from '../core/utils';

export default function DashboardPage() {
  const { data: customerCount, isLoading: lu } = useCustomerCount();
  const { data: companies, isLoading: lc } = useQuery({
    queryKey: ['stats', 'companies'],
    queryFn: () => companiesApi.getAll({ page: 1, pageSize: 1 }),
  });
  const { data: bookings, isLoading: lb } = useQuery({
    queryKey: ['stats', 'bookings'],
    queryFn: () => bookingsApi.getAll({ page: 1, pageSize: 1 }),
  });
  const { data: workers, isLoading: lw } = useQuery({
    queryKey: ['stats', 'workers'],
    queryFn: () => workersApi.getAll({ page: 1, pageSize: 1 }),
  });
  const { data: pendingCompanies } = useQuery({
    queryKey: ['stats', 'pending-companies'],
    queryFn: () => companiesApi.getAll({ page: 1, pageSize: 50 }),
    select: (d) => d.items.filter((c) => !c.isVerified).length,
  });
  const { data: inactiveVerifiedCompanies } = useQuery({
    queryKey: ['stats', 'inactive-companies'],
    queryFn: async () => {
      const [all, activeIds] = await Promise.all([
        companiesApi.fetchAll(),
        companiesApi.getActiveIds(),
      ]);
      return all.filter((c) => c.isVerified && !activeIds.has(c.id)).length;
    },
  });
  const { data: pendingReports } = useQuery({
    queryKey: ['reports', 'pending-count'],
    queryFn: reportsApi.countPending,
  });
  const { data: openBookingReports } = useOpenBookingReportsCount();
  const { data: financials } = useBookingFinancialStats();

  if (lu || lc || lb || lw) return <Loader />;

  return (
    <div>
      <PageHeader title="لوحة التحكم" subtitle="نظرة عامة على المنصة" />
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <KPICard title="العملاء" value={String(customerCount ?? 0)} icon={UserCircle} />
        <KPICard title="الشركات" value={String(companies?.totalCount ?? 0)} icon={Building2} />
        <KPICard title="الحجوزات" value={String(bookings?.totalCount ?? 0)} icon={Calendar} />
        <KPICard title="العاملات" value={String(workers?.totalCount ?? 0)} icon={UserCog} />
      </div>
      {financials && financials.completedPricedBookingsCount > 0 && (
        <>
          <h3 className="text-sm font-semibold text-gray-500 mb-1">ملخص مالي (الحجوزات المكتملة فقط)</h3>
          <p className="text-xs text-gray-400 mb-3">
            عمولة الشركة: {formatLyd(COMPANY_COMMISSION_PER_BOOKING_LYD)} لكل حجز مكتمل (تُخصم من سعر الخدمة)
            {' · '}
            {financials.completedPricedBookingsCount} حجز مكتمل بسعر مسجّل
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-4">
            <KPICard
              title="رسوم المنصة"
              value={formatLyd(financials.totalPlatformFees)}
              icon={Wallet}
            />
            <KPICard
              title="عمولة الشركة"
              value={formatLyd(financials.totalCompanyCommission)}
              icon={HandCoins}
            />
            <KPICard
              title="إجمالي العمولات"
              value={formatLyd(financials.totalCommissions)}
              icon={Sigma}
            />
          </div>
          <p className="text-xs text-gray-500 mb-4">
            رسوم المنصة + عمولة الشركة = {formatLyd(financials.totalPlatformFees)} +{' '}
            {formatLyd(financials.totalCompanyCommission)} = {formatLyd(financials.totalCommissions)}
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
            <KPICard
              title="إجمالي الإيرادات"
              value={formatLyd(financials.totalRevenue)}
              icon={Banknote}
            />
            <KPICard
              title="إيرادات الخدمات"
              value={formatLyd(financials.serviceRevenue)}
              icon={Coins}
            />
            <KPICard
              title="صافي الشركات (بعد العمولة)"
              value={formatLyd(financials.companyNetFromService)}
              icon={Building2}
            />
          </div>
        </>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="font-semibold text-gray-900 mb-4">طلبات التحقق المعلقة</h3>
          <p className="text-3xl font-bold text-bareq-600">{pendingCompanies ?? 0}</p>
          <p className="text-sm text-gray-500 mt-1">شركات بانتظار الاعتماد</p>
          {(inactiveVerifiedCompanies ?? 0) > 0 && (
            <p className="text-xs text-orange-600 mt-2">
              {inactiveVerifiedCompanies} موثقة غير مفعّلة
            </p>
          )}
        </div>
        <Link
          to={`${ROUTES.REPORTS}?status=0`}
          className="bg-white rounded-xl border border-gray-200 p-6 hover:border-bareq-300 transition-colors block"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-900">بلاغات العملاء</h3>
            <Flag className="w-5 h-5 text-bareq-600" />
          </div>
          <p className="text-3xl font-bold text-bareq-600">{pendingReports ?? 0}</p>
          <p className="text-sm text-gray-500 mt-1">بلاغات عاملات/شركات معلقة</p>
        </Link>
        <Link
          to={`${ROUTES.BOOKING_REPORTS}?status=0`}
          className="bg-white rounded-xl border border-gray-200 p-6 hover:border-bareq-300 transition-colors block"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-900">بلاغات حجوزات مفتوحة</h3>
            <CalendarClock className="w-5 h-5 text-bareq-600" />
          </div>
          <p className="text-3xl font-bold text-bareq-600">{openBookingReports ?? 0}</p>
          <p className="text-sm text-gray-500 mt-1">عرض بلاغات الحجوزات</p>
        </Link>
      </div>
    </div>
  );
}
