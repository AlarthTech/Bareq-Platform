import { useQuery } from '@tanstack/react-query';
import { Building2, Users, UserCheck, Calendar } from 'lucide-react';
import { dashboardApi } from '../../api';
import { KPICard } from '../../../../shared/components/KPICard';
import { StatusBadge } from '../../../../shared/components/StatusBadge';
import { PageHeader } from '../../../../shared/components/PageHeader';
import { Loader } from '../../../../shared/components/Loader';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

// Health Certificate Status colors: Valid (green), Almost Expired (orange), Expired (red)
const HEALTH_CERT_COLORS = ['#10b981', '#f59e0b', '#ef4444'];

export default function DashboardPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['dashboard', 'stats'],
    queryFn: dashboardApi.getStats,
  });

  if (isLoading) {
    return <Loader />;
  }

  if (!stats) {
    return <div>No data available</div>;
  }

  const chartData = [
    { name: 'Companies', value: stats.totalCompanies },
    { name: 'Workers', value: stats.totalWorkers },
    { name: 'Customers', value: stats.totalCustomers },
    { name: 'Bookings', value: stats.totalBookings },
  ];

  const healthCertData = [
    { name: 'Valid', value: stats.healthCertificates.valid },
    { name: 'Almost Expired', value: stats.healthCertificates.almostExpired },
    { name: 'Expired', value: stats.healthCertificates.expired },
  ];

  return (
    <div>
      <PageHeader title="Dashboard" />
      
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <KPICard
          title="Total Companies"
          value={stats.totalCompanies.toLocaleString()}
          icon={Building2}
        />
        <KPICard
          title="Total Workers"
          value={stats.totalWorkers.toLocaleString()}
          icon={UserCheck}
        />
        <KPICard
          title="Total Customers"
          value={stats.totalCustomers.toLocaleString()}
          icon={Users}
        />
        <KPICard
          title="Total Bookings"
          value={stats.totalBookings.toLocaleString()}
          icon={Calendar}
        />
      </div>

      {/* Status Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Pending Approvals</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Pending Companies</span>
              <div className="flex items-center gap-2">
                <StatusBadge status="pending" />
                <span className="text-lg font-semibold text-gray-900">
                  {stats.pendingCompanies}
                </span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Pending Workers</span>
              <div className="flex items-center gap-2">
                <StatusBadge status="pending" />
                <span className="text-lg font-semibold text-gray-900">
                  {stats.pendingWorkers}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Health Certificates</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Valid</span>
              <div className="flex items-center gap-2">
                <StatusBadge status="valid" />
                <span className="text-lg font-semibold text-gray-900">
                  {stats.healthCertificates.valid.toLocaleString()}
                </span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Almost Expired</span>
              <div className="flex items-center gap-2">
                <StatusBadge status="almost_expired" />
                <span className="text-lg font-semibold text-gray-900">
                  {stats.healthCertificates.almostExpired.toLocaleString()}
                </span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Expired</span>
              <div className="flex items-center gap-2">
                <StatusBadge status="expired" />
                <span className="text-lg font-semibold text-gray-900">
                  {stats.healthCertificates.expired.toLocaleString()}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Overview</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="value" fill="#0ea5e9" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Health Certificates Status</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={healthCertData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${percent ? (percent * 100).toFixed(0) : 0}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {healthCertData.map((_, index) => (
                  <Cell key={`cell-${index}`} fill={HEALTH_CERT_COLORS[index % HEALTH_CERT_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
