import { ValidationError } from '../errors';

export function getErrorMessage(err: unknown): string {
  if (err instanceof ValidationError) {
    if (err.message && err.message !== 'Validation error') {
      return err.message;
    }
    const firstFieldError = err.errors
      ? Object.values(err.errors).flat().find(Boolean)
      : undefined;
    if (firstFieldError) return firstFieldError;
  }
  if (err instanceof Error) return err.message;
  if (typeof err === 'string') return err;
  return 'حدث خطأ غير متوقع';
}
