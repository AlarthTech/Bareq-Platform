import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { walletApi } from '../api/wallet.api';
import type {
  ApproveBankTransferDTO,
  BulkWalletCreditRequest,
  RejectBankTransferDTO,
  WalletCreditRequest,
  WalletTopUpStatus,
} from '../types';

export const BANK_ACCOUNTS_KEY = ['admin', 'wallet-bank-accounts'] as const;
export const BANK_TRANSFERS_KEY = ['admin', 'wallet-bank-transfers'] as const;
export const BANK_CARDS_KEY = ['admin', 'wallet-bank-cards'] as const;
export const PENDING_BANK_TRANSFER_KEY = ['admin', 'wallet-bank-transfers', 'pending-count'] as const;

export function usePendingBankTransferCount() {
  return useQuery({
    queryKey: PENDING_BANK_TRANSFER_KEY,
    queryFn: () => walletApi.getBankTransferTopUps({ status: 'Pending', page: 1, pageSize: 50 }),
    select: (items) =>
      items.filter((t) => t.status === 'Pending' && t.paymentMethod === 'BankTransfer').length,
    staleTime: 30_000,
  });
}

export function useBankTransferTopUps(status: WalletTopUpStatus | '') {
  return useQuery({
    queryKey: [...BANK_TRANSFERS_KEY, status || 'all'],
    queryFn: () =>
      walletApi.getBankTransferTopUps({
        ...(status ? { status } : {}),
        page: 1,
        pageSize: 50,
      }),
  });
}

export function useBankTransferDetail(id: number | null) {
  return useQuery({
    queryKey: [...BANK_TRANSFERS_KEY, 'detail', id],
    queryFn: () => walletApi.getBankTransferTopUp(id!),
    enabled: id != null && id > 0,
  });
}

export function useBankTransferActions() {
  const qc = useQueryClient();

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: BANK_TRANSFERS_KEY });
    qc.invalidateQueries({ queryKey: PENDING_BANK_TRANSFER_KEY });
  };

  const approve = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: ApproveBankTransferDTO }) =>
      walletApi.approveBankTransfer(id, payload),
    onSuccess: invalidate,
  });

  const reject = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: RejectBankTransferDTO }) =>
      walletApi.rejectBankTransfer(id, payload),
    onSuccess: invalidate,
  });

  return { approve, reject };
}

export function useBankCardTopUps(status: WalletTopUpStatus | '') {
  return useQuery({
    queryKey: [...BANK_CARDS_KEY, status || 'all'],
    queryFn: () =>
      walletApi.getBankCardTopUps({
        ...(status ? { status } : {}),
        page: 1,
        pageSize: 50,
      }),
  });
}

export function useBankCardActions() {
  const qc = useQueryClient();

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: BANK_CARDS_KEY });
  };

  const confirm = useMutation({
    mutationFn: (id: number) => walletApi.confirmBankCardTopUp(id),
    onSuccess: invalidate,
  });

  const fail = useMutation({
    mutationFn: (id: number) => walletApi.failBankCardTopUp(id),
    onSuccess: invalidate,
  });

  return { confirm, fail };
}

export function useWalletCreditActions() {
  const credit = useMutation({
    mutationFn: ({ customerId, ...payload }: WalletCreditRequest & { customerId: number }) =>
      walletApi.creditWallet(customerId, payload),
  });

  const bulkCredit = useMutation({
    mutationFn: (payload: BulkWalletCreditRequest) => walletApi.bulkCreditWallets(payload),
  });

  return { credit, bulkCredit };
}
