import { useEffect, useState } from 'react';
import { Info } from 'lucide-react';
import { Button } from '../../../shared/ui/Button';
import { formatDateTime, formatLyd } from '../../../core/utils';
import { useWalletSettings, useUpdateWalletSettings } from '../hooks/useWalletSettings';
import { previewWalletDebit, validateWalletFeePercentage } from '../utils/validateWalletFee';
import { useToast } from '../../../shared/context/ToastContext';
import { getErrorMessage } from '../../../core/utils/getErrorMessage';

const PREVIEW_BOOKING_TOTAL = 100;

export function WalletSettingsForm() {
  const { showToast } = useToast();
  const { data, isLoading, isError, refetch } = useWalletSettings();
  const updateMutation = useUpdateWalletSettings();

  const [enabled, setEnabled] = useState(false);
  const [feePercent, setFeePercent] = useState('');
  const [fieldError, setFieldError] = useState<string | null>(null);

  useEffect(() => {
    if (data) {
      setEnabled(data.isWalletPaymentEnabled);
      setFeePercent(String(data.walletPaymentFeePercentage));
    }
  }, [data]);

  const parsedFee = Number.parseFloat(feePercent);
  const validationError = feePercent === '' ? null : validateWalletFeePercentage(parsedFee);
  const unchanged =
    data != null &&
    enabled === data.isWalletPaymentEnabled &&
    !Number.isNaN(parsedFee) &&
    parsedFee === data.walletPaymentFeePercentage;

  const canSave =
    !isLoading &&
    !updateMutation.isPending &&
    feePercent !== '' &&
    !validationError &&
    !unchanged;

  const previewDebit =
    !Number.isNaN(parsedFee) && parsedFee >= 0
      ? previewWalletDebit(PREVIEW_BOOKING_TOTAL, parsedFee)
      : null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const error = validateWalletFeePercentage(parsedFee);
    if (error) {
      setFieldError(error);
      return;
    }
    setFieldError(null);
    try {
      await updateMutation.mutateAsync({
        isWalletPaymentEnabled: enabled,
        walletPaymentFeePercentage: parsedFee,
      });
      showToast('تم حفظ إعدادات المحفظة بنجاح', 'success');
    } catch (err) {
      showToast(getErrorMessage(err), 'error');
    }
  };

  if (isLoading) {
    return (
      <div className="bg-white rounded-xl border p-6 animate-pulse space-y-4">
        <div className="h-6 bg-gray-100 rounded w-1/3" />
        <div className="h-10 bg-gray-100 rounded w-full max-w-xs" />
        <div className="h-10 bg-gray-100 rounded w-32" />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="bg-white rounded-xl border p-6 text-center">
        <p className="text-gray-600 mb-4">تعذر تحميل إعدادات المحفظة</p>
        <Button type="button" variant="outline" onClick={() => refetch()}>
          إعادة المحاولة
        </Button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="bg-white rounded-xl border p-6 space-y-6">
      <label className="flex items-center justify-between gap-4 cursor-pointer">
        <div>
          <p className="font-medium text-gray-900">تفعيل الدفع بالمحفظة</p>
          <p className="text-sm text-gray-500 mt-0.5">السماح للعملاء بالدفع من رصيد المحفظة</p>
        </div>
        <button
          type="button"
          role="switch"
          aria-checked={enabled}
          onClick={() => setEnabled((v) => !v)}
          className={`relative w-11 h-6 rounded-full transition-colors ${enabled ? 'bg-bareq-600' : 'bg-gray-200'}`}
        >
          <span
            className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${enabled ? 'right-0.5' : 'right-[1.375rem]'}`}
          />
        </button>
      </label>

      <div>
        <label htmlFor="wallet-fee-percent" className="block text-sm font-medium text-gray-700 mb-2">
          نسبة رسوم الدفع بالمحفظة (%)
        </label>
        <div className="flex items-center gap-2 max-w-xs">
          <input
            id="wallet-fee-percent"
            type="number"
            min={0}
            max={100}
            step={0.01}
            value={feePercent}
            onChange={(e) => {
              setFeePercent(e.target.value);
              setFieldError(null);
            }}
            className="flex-1 border border-gray-200 rounded-lg px-3 py-2.5 tabular-nums focus:ring-2 focus:ring-bareq-500"
          />
          <span className="text-gray-600">%</span>
        </div>
        {(fieldError || validationError) && (
          <p className="text-sm text-red-600 mt-2">{fieldError ?? validationError}</p>
        )}
      </div>

      {previewDebit != null && enabled && (
        <div className="flex gap-3 items-start rounded-lg bg-emerald-50 text-emerald-900 text-sm p-4">
          <Info className="w-5 h-5 shrink-0 mt-0.5" />
          <p>
            على حجز بقيمة {formatLyd(PREVIEW_BOOKING_TOTAL)}، يُخصم من المحفظة:{' '}
            <strong>{formatLyd(previewDebit)}</strong>
            {parsedFee > 0 && (
              <span className="text-emerald-700"> (رسوم {parsedFee}% = {formatLyd(previewDebit - PREVIEW_BOOKING_TOTAL)})</span>
            )}
          </p>
        </div>
      )}

      {data && (
        <p className="text-xs text-gray-500 border-t pt-4">
          آخر تحديث: {formatDateTime(data.updatedAt)}
          {data.updatedByAdminId != null && ` · المشرف #${data.updatedByAdminId}`}
        </p>
      )}

      <Button type="submit" disabled={!canSave}>
        {updateMutation.isPending ? 'جاري الحفظ...' : 'حفظ التغييرات'}
      </Button>
    </form>
  );
}
