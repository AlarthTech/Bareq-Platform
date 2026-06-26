import type { CompanyDisplayStatus } from '../../core/utils/companyStatus';
import { COMPANY_STATUS_LABELS } from '../../core/utils/companyStatus';
import { classNames } from '../../core/utils';

const statusStyles: Record<CompanyDisplayStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  active: 'bg-green-100 text-green-800',
  inactive: 'bg-orange-100 text-orange-800',
};

export function CompanyStatusBadge({ status }: { status: CompanyDisplayStatus }) {
  return (
    <span
      className={classNames(
        'inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium',
        statusStyles[status]
      )}
    >
      {COMPANY_STATUS_LABELS[status]}
    </span>
  );
}
