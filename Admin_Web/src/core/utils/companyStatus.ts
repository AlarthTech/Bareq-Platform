export type CompanyDisplayStatus = 'pending' | 'active' | 'inactive';

export function getCompanyDisplayStatus(
  company: { id: number; isVerified: boolean },
  activeCompanyIds: Set<number>
): CompanyDisplayStatus {
  if (!company.isVerified) return 'pending';
  return activeCompanyIds.has(company.id) ? 'active' : 'inactive';
}

export const COMPANY_STATUS_LABELS: Record<CompanyDisplayStatus, string> = {
  pending: 'بانتظار الاعتماد',
  active: 'نشطة',
  inactive: 'موثقة — غير مفعّلة',
};
