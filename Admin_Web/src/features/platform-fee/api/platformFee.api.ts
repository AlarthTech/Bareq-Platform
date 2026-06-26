import { apiClient } from '../../../core/api/client';
import type {
  PlatformFeeResponse,
  UpdatePlatformFeeRequest,
  UpdatePlatformFeeResponse,
} from '../types';

type ApiPlatformFeePayload = {
  amount?: number;
  fixedPlatformFeeAmount?: number;
  success?: boolean;
};

function normalizeAmount(data: ApiPlatformFeePayload): number {
  return data.amount ?? data.fixedPlatformFeeAmount ?? 0;
}

export const platformFeeApi = {
  get: async (): Promise<PlatformFeeResponse> => {
    const data = await apiClient.get<ApiPlatformFeePayload>('/v1/admin/platform-fee');
    return { fixedPlatformFeeAmount: normalizeAmount(data) };
  },

  update: async (payload: UpdatePlatformFeeRequest): Promise<UpdatePlatformFeeResponse> => {
    const data = await apiClient.put<ApiPlatformFeePayload>('/v1/admin/platform-fee', {
      amount: payload.fixedPlatformFeeAmount,
    });
    return {
      success: data.success ?? true,
      fixedPlatformFeeAmount: normalizeAmount(data),
    };
  },
};
