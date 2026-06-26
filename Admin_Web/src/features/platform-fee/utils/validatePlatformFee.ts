export function validatePlatformFee(value: number): string | null {
  if (Number.isNaN(value)) return 'يرجى إدخال مبلغ صالح';
  if (value < 0) return 'لا يمكن أن تكون رسوم المنصة سالبة';
  return null;
}

/** Prompt confirm when fee increases by at least this amount (LYD). */
export const PLATFORM_FEE_INCREASE_CONFIRM_THRESHOLD = 5;

export function shouldConfirmFeeIncrease(current: number, next: number): boolean {
  return next > current && next - current >= PLATFORM_FEE_INCREASE_CONFIRM_THRESHOLD;
}
