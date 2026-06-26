export function validateWalletFeePercentage(value: number): string | null {
  if (Number.isNaN(value)) return 'يرجى إدخال نسبة صالحة';
  if (value < 0 || value > 100) return 'يجب أن تكون النسبة بين 0 و 100';
  return null;
}

/** Preview wallet debit for a booking total (stored totalPrice). */
export function previewWalletDebit(bookingTotal: number, feePercentage: number): number {
  return bookingTotal * (1 + feePercentage / 100);
}
