import type { PagedResult } from '../../types/api.types';

export interface WalletPaymentSettingsDTO {
  isWalletPaymentEnabled: boolean;
  walletPaymentFeePercentage: number;
  updatedAt: string;
  updatedByAdminId: number | null;
}

export interface UpdateWalletPaymentSettingsDTO {
  isWalletPaymentEnabled: boolean;
  walletPaymentFeePercentage: number;
}

export type WalletTopUpStatus = 'Pending' | 'Completed' | 'Rejected' | 'Failed';

export interface BankAccountDTO {
  id: number;
  bankName: string;
  accountHolderName: string;
  accountNumber: string;
  iban: string;
  branchName?: string | null;
  instructions?: string | null;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateBankAccountDTO {
  bankName: string;
  accountHolderName: string;
  accountNumber: string;
  iban: string;
  branchName?: string;
  instructions?: string;
  isActive?: boolean;
}

export type UpdateBankAccountDTO = CreateBankAccountDTO;

export type WalletTopUpPaymentMethod = 'BankCard' | 'BankTransfer';

export interface WalletTopUpDTO {
  id: number;
  customerId?: number;
  customerName?: string;
  requestedAmount: number;
  approvedAmount?: number | null;
  paymentMethod: WalletTopUpPaymentMethod;
  status: WalletTopUpStatus;
  referenceNumber?: string | null;
  notes?: string | null;
  adminNotes?: string | null;
  rejectionReason?: string | null;
  createdAt: string;
  completedAt?: string | null;
}

export type BankTransferTopUpDTO = WalletTopUpDTO & { paymentMethod: 'BankTransfer' };
export type BankCardTopUpDTO = WalletTopUpDTO & { paymentMethod: 'BankCard' };

export interface ApproveBankTransferDTO {
  approvedAmount: number;
  adminNotes?: string;
}

export interface RejectBankTransferDTO {
  reason: string;
}

export interface WalletCreditRequest {
  amount: number;
  notes?: string;
}

export interface BulkWalletCreditRequest {
  customerIds: number[];
  amount: number;
  notes?: string;
}

export interface WalletCreditResponse {
  creditedCustomerIds: number[];
  creditedPhoneNumbers?: string[];
}

export type WalletTopUpListResult = PagedResult<WalletTopUpDTO> | WalletTopUpDTO[];
export type BankTransferListResult = WalletTopUpListResult;
export type BankCardListResult = WalletTopUpListResult;

export const WALLET_TOP_UP_STATUS_LABELS: Record<WalletTopUpStatus, string> = {
  Pending: 'قيد الانتظار',
  Completed: 'مكتمل',
  Rejected: 'مرفوض',
  Failed: 'فشل',
};

export const WALLET_TOP_UP_STATUS_COLORS: Record<WalletTopUpStatus, string> = {
  Pending: 'bg-yellow-100 text-yellow-800',
  Completed: 'bg-green-100 text-green-800',
  Rejected: 'bg-red-100 text-red-800',
  Failed: 'bg-gray-100 text-gray-800',
};
