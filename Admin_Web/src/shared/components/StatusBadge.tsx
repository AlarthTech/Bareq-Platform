import type { Status, HealthCertificateStatus } from '../../core/types';
import { classNames } from '../../core/utils';

interface StatusBadgeProps {
  status: Status | HealthCertificateStatus;
  className?: string;
}

const statusConfig: Record<string, { label: string; className: string }> = {
  pending: {
    label: 'Pending',
    className: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  },
  approved: {
    label: 'Approved',
    className: 'bg-green-100 text-green-800 border-green-200',
  },
  rejected: {
    label: 'Rejected',
    className: 'bg-red-100 text-red-800 border-red-200',
  },
  active: {
    label: 'Active',
    className: 'bg-blue-100 text-blue-800 border-blue-200',
  },
  inactive: {
    label: 'Inactive',
    className: 'bg-gray-100 text-gray-800 border-gray-200',
  },
  valid: {
    label: 'Valid',
    className: 'bg-green-100 text-green-800 border-green-200',
  },
  almost_expired: {
    label: 'Almost Expired',
    className: 'bg-orange-100 text-orange-800 border-orange-200',
  },
  expired: {
    label: 'Expired',
    className: 'bg-red-100 text-red-800 border-red-200',
  },
};

export const StatusBadge = ({ status, className }: StatusBadgeProps) => {
  const config = statusConfig[status] || {
    label: status,
    className: 'bg-gray-100 text-gray-800 border-gray-200',
  };

  return (
    <span
      className={classNames(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border',
        config.className,
        className
      )}
    >
      {config.label}
    </span>
  );
};
