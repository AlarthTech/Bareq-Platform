import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { platformFeeApi } from '../api/platformFee.api';
import type { UpdatePlatformFeeRequest } from '../types';

export const PLATFORM_FEE_QUERY_KEY = ['platform-fee'] as const;

export function usePlatformFee() {
  return useQuery({
    queryKey: PLATFORM_FEE_QUERY_KEY,
    queryFn: () => platformFeeApi.get(),
    retry: 1,
    staleTime: 60_000,
  });
}

export function useUpdatePlatformFee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: UpdatePlatformFeeRequest) => platformFeeApi.update(payload),
    onSuccess: (data) => {
      queryClient.setQueryData(PLATFORM_FEE_QUERY_KEY, {
        fixedPlatformFeeAmount: data.fixedPlatformFeeAmount,
      });
    },
  });
}
