import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { walletApi } from '../api/wallet.api';
import type { CreateBankAccountDTO, UpdateBankAccountDTO } from '../types';
import { BANK_ACCOUNTS_KEY } from './useWalletTopUps';

export function useBankAccounts() {
  return useQuery({
    queryKey: BANK_ACCOUNTS_KEY,
    queryFn: () => walletApi.getBankAccounts(),
    retry: 1,
  });
}

export function useBankAccountMutations() {
  const qc = useQueryClient();

  const invalidate = () => qc.invalidateQueries({ queryKey: BANK_ACCOUNTS_KEY });

  const create = useMutation({
    mutationFn: (payload: CreateBankAccountDTO) => walletApi.createBankAccount(payload),
    onSuccess: invalidate,
  });

  const update = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: UpdateBankAccountDTO }) =>
      walletApi.updateBankAccount(id, payload),
    onSuccess: invalidate,
  });

  const activate = useMutation({
    mutationFn: (id: number) => walletApi.activateBankAccount(id),
    onSuccess: invalidate,
  });

  const deactivate = useMutation({
    mutationFn: (id: number) => walletApi.deactivateBankAccount(id),
    onSuccess: invalidate,
  });

  return { create, update, activate, deactivate };
}
