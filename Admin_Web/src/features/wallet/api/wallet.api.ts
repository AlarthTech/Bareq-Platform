import { apiClient } from '../../../core/api/client';
import type {
  ApproveBankTransferDTO,
  BankAccountDTO,
  BankCardTopUpDTO,
  BankTransferTopUpDTO,
  BulkWalletCreditRequest,
  CreateBankAccountDTO,
  RejectBankTransferDTO,
  UpdateBankAccountDTO,
  UpdateWalletPaymentSettingsDTO,
  WalletCreditRequest,
  WalletCreditResponse,
  WalletPaymentSettingsDTO,
  WalletTopUpListResult,
} from '../types';

function normalizeTopUpList<T>(data: WalletTopUpListResult): T[] {
  return (Array.isArray(data) ? data : data.items) as T[];
}

export const walletApi = {
  getSettings: () =>
    apiClient.get<WalletPaymentSettingsDTO>('/v1/admin/payment-settings/wallet'),

  updateSettings: (payload: UpdateWalletPaymentSettingsDTO) =>
    apiClient.put<WalletPaymentSettingsDTO>('/v1/admin/payment-settings/wallet', payload),

  getBankAccounts: () => apiClient.get<BankAccountDTO[]>('/v1/admin/wallet/bank-accounts'),

  createBankAccount: (payload: CreateBankAccountDTO) =>
    apiClient.post<BankAccountDTO>('/v1/admin/wallet/bank-accounts', payload),

  updateBankAccount: (id: number, payload: UpdateBankAccountDTO) =>
    apiClient.put<BankAccountDTO>(`/v1/admin/wallet/bank-accounts/${id}`, payload),

  activateBankAccount: (id: number) =>
    apiClient.post<BankAccountDTO>(`/v1/admin/wallet/bank-accounts/${id}/activate`),

  deactivateBankAccount: (id: number) =>
    apiClient.post<BankAccountDTO>(`/v1/admin/wallet/bank-accounts/${id}/deactivate`),

  getBankTransferTopUps: async (params: { status?: string; page?: number; pageSize?: number } = {}) => {
    const data = await apiClient.get<WalletTopUpListResult>(
      '/v1/admin/wallet/top-ups/bank-transfers',
      {
        page: params.page ?? 1,
        pageSize: params.pageSize ?? 20,
        ...(params.status ? { status: params.status } : {}),
      }
    );
    return normalizeTopUpList<BankTransferTopUpDTO>(data);
  },

  getBankTransferTopUp: (id: number) =>
    apiClient.get<BankTransferTopUpDTO>(`/v1/admin/wallet/top-ups/bank-transfers/${id}`),

  approveBankTransfer: (id: number, payload: ApproveBankTransferDTO) =>
    apiClient.post<BankTransferTopUpDTO>(
      `/v1/admin/wallet/top-ups/bank-transfers/${id}/approve`,
      payload
    ),

  rejectBankTransfer: (id: number, payload: RejectBankTransferDTO) =>
    apiClient.post<BankTransferTopUpDTO>(
      `/v1/admin/wallet/top-ups/bank-transfers/${id}/reject`,
      payload
    ),

  getBankCardTopUps: async (params: { status?: string; page?: number; pageSize?: number } = {}) => {
    const data = await apiClient.get<WalletTopUpListResult>(
      '/v1/admin/wallet/top-ups/bank-cards',
      {
        page: params.page ?? 1,
        pageSize: params.pageSize ?? 20,
        ...(params.status ? { status: params.status } : {}),
      }
    );
    return normalizeTopUpList<BankCardTopUpDTO>(data);
  },

  confirmBankCardTopUp: (id: number) =>
    apiClient.post<BankCardTopUpDTO>(`/v1/admin/wallet/top-ups/${id}/confirm-bank-card`),

  failBankCardTopUp: (id: number) =>
    apiClient.post<BankCardTopUpDTO>(`/v1/admin/wallet/top-ups/${id}/fail-bank-card`),

  creditWallet: (customerId: number, payload: WalletCreditRequest) =>
    apiClient.post<WalletCreditResponse>(
      `/v1/admin/wallet/wallets/${customerId}/credit`,
      payload
    ),

  bulkCreditWallets: (payload: BulkWalletCreditRequest) =>
    apiClient.post<WalletCreditResponse>('/v1/admin/wallet/wallets/bulk-credit', payload),
};
