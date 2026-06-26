import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { walletApi } from '../api/wallet.api';
import type { UpdateWalletPaymentSettingsDTO } from '../types';

export const WALLET_SETTINGS_KEY = ['admin', 'wallet-settings'] as const;

export function useWalletSettings() {
  return useQuery({
    queryKey: WALLET_SETTINGS_KEY,
    queryFn: () => walletApi.getSettings(),
    retry: 1,
    staleTime: 60_000,
  });
}

export function useUpdateWalletSettings() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: UpdateWalletPaymentSettingsDTO) => walletApi.updateSettings(payload),
    onSuccess: (data) => {
      queryClient.setQueryData(WALLET_SETTINGS_KEY, data);
    },
  });
}
