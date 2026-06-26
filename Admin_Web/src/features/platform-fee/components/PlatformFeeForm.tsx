import { useEffect, useState } from 'react';
import { Info } from 'lucide-react';
import { Button } from '../../../shared/ui/Button';
import { ConfirmModal } from '../../../shared/components/ConfirmModal';
import { formatLyd } from '../../../core/utils';
import { usePlatformFee, useUpdatePlatformFee } from '../hooks/usePlatformFee';
import {
  shouldConfirmFeeIncrease,
  validatePlatformFee,
} from '../utils/validatePlatformFee';
import { useToast } from '../../../shared/context/ToastContext';
import { getErrorMessage } from '../../../core/utils/getErrorMessage';

export function PlatformFeeForm() {
  const { showToast } = useToast();
  const { data, isLoading, isError, refetch } = usePlatformFee();
  const updateMutation = useUpdatePlatformFee();

  const [amount, setAmount] = useState('');
  const [fieldError, setFieldError] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingValue, setPendingValue] = useState<number | null>(null);

  const savedAmount = data?.fixedPlatformFeeAmount ?? 0;

  useEffect(() => {
    if (data != null) {
      setAmount(String(data.fixedPlatformFeeAmount));
    }
  }, [data?.fixedPlatformFeeAmount]);

  const parsed = Number.parseFloat(amount);
  const validationError = amount === '' ? null : validatePlatformFee(parsed);
  const unchanged = !Number.isNaN(parsed) && parsed === savedAmount;
  const canSave =
    !isLoading &&
    !updateMutation.isPending &&
    amount !== '' &&
    !validationError &&
    !unchanged;

  const submitValue = async (value: number) => {
    try {
      await updateMutation.mutateAsync({ fixedPlatformFeeAmount: value });
      showToast('تم تحديث رسوم المنصة بنجاح', 'success');
      setConfirmOpen(false);
      setPendingValue(null);
    } catch (e) {
      showToast(getErrorMessage(e), 'error');
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const error = validatePlatformFee(parsed);
    if (error) {
      setFieldError(error);
      return;
    }
    setFieldError(null);

    if (shouldConfirmFeeIncrease(savedAmount, parsed)) {
      setPendingValue(parsed);
      setConfirmOpen(true);
      return;
    }

    void submitValue(parsed);
  };

  if (isLoading) {
    return (
      <div className="bg-white rounded-xl border p-6 animate-pulse space-y-4">
        <div className="h-6 bg-gray-100 rounded w-1/3" />
        <div className="h-12 bg-gray-100 rounded w-48" />
        <div className="h-10 bg-gray-100 rounded w-32" />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="bg-white rounded-xl border p-6 text-center">
        <p className="text-gray-600 mb-4">تعذر تحميل رسوم المنصة</p>
        <Button type="button" variant="outline" onClick={() => refetch()}>
          إعادة المحاولة
        </Button>
      </div>
    );
  }

  return (
    <>
      <form onSubmit={handleSubmit} className="bg-white rounded-xl border p-6 space-y-5">
        <div>
          <p className="text-sm text-gray-600 mb-3">المبلغ الثابت المضاف على كل حجز جديد</p>
          <div className="flex items-center gap-2 max-w-xs">
            <input
              type="number"
              min={0}
              step={0.01}
              value={amount}
              onChange={(e) => {
                setAmount(e.target.value);
                setFieldError(null);
              }}
              className="flex-1 border border-gray-200 rounded-lg px-3 py-2.5 text-lg font-medium tabular-nums focus:ring-2 focus:ring-bareq-500 focus:border-bareq-500"
              aria-label="رسوم المنصة بالدينار الليبي"
            />
            <span className="text-gray-600 font-medium shrink-0">د.ل</span>
          </div>
          {(fieldError || validationError) && (
            <p className="text-sm text-red-600 mt-2">{fieldError ?? validationError}</p>
          )}
          <p className="text-xs text-gray-500 mt-2">
            الرسوم الحالية المحفوظة: {formatLyd(savedAmount)}
          </p>
        </div>

        <div className="flex gap-3 items-start rounded-lg bg-blue-50 text-blue-900 text-sm p-4">
          <Info className="w-5 h-5 shrink-0 mt-0.5" />
          <p>
            يُطبَّق على الحجوزات الجديدة فقط. الحجوزات السابقة تحتفظ بالرسوم المحفوظة عند إنشائها.
          </p>
        </div>

        <Button type="submit" disabled={!canSave}>
          {updateMutation.isPending ? 'جاري الحفظ...' : 'حفظ التغييرات'}
        </Button>
      </form>

      <ConfirmModal
        isOpen={confirmOpen}
        onClose={() => {
          setConfirmOpen(false);
          setPendingValue(null);
        }}
        onConfirm={() => pendingValue != null && void submitValue(pendingValue)}
        title="تأكيد زيادة رسوم المنصة"
        message="سيتم تطبيق الرسوم الجديدة على الحجوزات القادمة فقط. هل تريد المتابعة؟"
        confirmText="متابعة"
        cancelText="إلغاء"
        variant="warning"
        isLoading={updateMutation.isPending}
      />
    </>
  );
}
