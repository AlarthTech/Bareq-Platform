import type { LucideIcon } from 'lucide-react';
import { classNames } from '../../core/utils';

interface KPICardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  className?: string;
}

export const KPICard = ({
  title,
  value,
  icon: Icon,
  trend,
  className,
}: KPICardProps) => {
  return (
    <div
      className={classNames(
        'bg-white rounded-lg shadow-sm border border-gray-200 p-6',
        className
      )}
    >
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600 mb-1">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
          {trend && (
            <p
              className={classNames(
                'text-xs mt-2',
                trend.isPositive ? 'text-green-600' : 'text-red-600'
              )}
            >
              {trend.isPositive ? '↑' : '↓'} {Math.abs(trend.value)}% from last month
            </p>
          )}
        </div>
        <div className="ml-4">
          <div className="flex items-center justify-center w-12 h-12 bg-blue-50 rounded-lg">
            <Icon className="w-6 h-6 text-blue-600" />
          </div>
        </div>
      </div>
    </div>
  );
};
