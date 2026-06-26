import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { companiesApi } from '../api/companies.api';
import {
  getCompanyDisplayStatus,
  type CompanyDisplayStatus,
} from '../core/utils/companyStatus';
import type { Company } from '../types/api.types';

export interface CompanyWithStatus extends Company {
  displayStatus: CompanyDisplayStatus;
  isActiveOnPlatform: boolean;
}

export function useActiveCompanyIds() {
  return useQuery({
    queryKey: ['companies', 'active-ids'],
    queryFn: companiesApi.getActiveIds,
    staleTime: 30_000,
  });
}

export function useCompaniesWithStatus(companies: Company[] | undefined) {
  const { data: activeIds = new Set<number>(), isLoading } = useActiveCompanyIds();

  const enriched = useMemo<CompanyWithStatus[]>(() => {
    if (!companies) return [];
    return companies.map((company) => {
      const isActiveOnPlatform = activeIds.has(company.id);
      return {
        ...company,
        isActiveOnPlatform,
        displayStatus: getCompanyDisplayStatus(company, activeIds),
      };
    });
  }, [companies, activeIds]);

  const counts = useMemo(
    () => ({
      pending: enriched.filter((c) => c.displayStatus === 'pending').length,
      active: enriched.filter((c) => c.displayStatus === 'active').length,
      inactive: enriched.filter((c) => c.displayStatus === 'inactive').length,
    }),
    [enriched]
  );

  return { companies: enriched, counts, activeIds, isLoading };
}
