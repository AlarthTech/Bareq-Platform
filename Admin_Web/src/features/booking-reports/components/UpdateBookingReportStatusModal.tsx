import { useEffect, useState } from 'react';
import { FormModal } from '../../../shared/forms/FormModal';
import { Button } from '../../../shared/ui/Button';
import {
  ADMIN_BOOKING_REPORT_STATUS_OPTIONS,
  ADMIN_RESOLUTION_NOTES_MAX,
  BookingReportStatus,
  type AdminBookingReportStatusValue,
  type BookingReport,
} from '../../../types/booking-report';

interface UpdateBookingReportStatusModalProps {
  report: BookingReport | null;
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (payload: { status: AdminBookingReportStatusValue; adminResolutionNotes?: string }) => Promise<void>;
  isLoading?: boolean;
}

function notesRequired(status: AdminBookingReportStatusValue): boolean {
  return status === BookingReportStatus.Resolved || status === BookingReportStatus.Rejected;
}

export function UpdateBookingReportStatusModal({
  report,
  isOpen,
  onClose,
  onSubmit,
  isLoading = false,
}: UpdateBookingReportStatusModalProps) {
  const [status, setStatus] = useState<AdminBookingReportStatusValue>(BookingReportStatus.InReview);
  const [notes, setNotes] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!report || !isOpen) return;
    const nextStatus =
      report.status === BookingReportStatus.Open
        ? BookingReportStatus.InReview
        : report.status === BookingReportStatus.InReview
          ? BookingReportStatus.InReview
          : BookingReportStatus.InReview;
    setStatus(nextStatus);
    setNotes(report.adminResolutionNotes ?? '');
    setError(null);
  }, [report, isOpen]);

  if (!report) return null;

  const sameStatus = status === report.status;
  const trimmedNotes = notes.trim();
  const needsNotes = notesRequired(status);
  const notesInvalid = needsNotes && !trimmedNotes;
  const canSubmit = !isLoading && !sameStatus && !notesInvalid;

  const handleSubmit = async () => {
    if (needsNotes && !trimmedNotes) {
      setError('ملاحظات الإدارة مطلوبة عند حل البلاغ أو رفضه');
      return;
    }
    if (sameStatus) {
      setError('البلاغ في هذه الحالة بالفعل');
      return;
    }
    setError(null);
    await onSubmit({
      status,
      adminResolutionNotes: trimmedNotes || undefined,
    });
  };

  const quickSet = (next: AdminBookingReportStatusValue) => {
    setStatus(next);
    setError(null);
  };

  return (
    <FormModal
      isOpen={isOpen}
      onClose={onClose}
      title={`تحديث حالة البلاغ #${report.id}`}
      footer={
        <>
          <Button type="button" variant="outline" onClick={onClose}>
            إلغاء
          </Button>
          <Button type="button" disabled={!canSubmit} onClick={() => void handleSubmit()}>
            {isLoading ? 'جاري الحفظ...' : 'حفظ'}
          </Button>
        </>
      }
    >
      <div className="space-y-4 text-right">
        {report.status === BookingReportStatus.Open && (
          <div className="flex flex-wrap gap-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => quickSet(BookingReportStatus.InReview)}
            >
              بدء المراجعة
            </Button>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => quickSet(BookingReportStatus.Resolved)}
            >
              تم الحل
            </Button>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => quickSet(BookingReportStatus.Rejected)}
            >
              رفض البلاغ
            </Button>
          </div>
        )}

        <div>
          <label className="block text-sm font-medium mb-1">الحالة الجديدة</label>
          <select
            value={status}
            onChange={(e) => {
              setStatus(Number(e.target.value) as AdminBookingReportStatusValue);
              setError(null);
            }}
            className="w-full border rounded-lg px-3 py-2 text-sm"
          >
            {ADMIN_BOOKING_REPORT_STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">
            ملاحظات الإدارة
            {needsNotes && <span className="text-red-600"> *</span>}
          </label>
          <textarea
            value={notes}
            onChange={(e) => {
              setNotes(e.target.value.slice(0, ADMIN_RESOLUTION_NOTES_MAX));
              setError(null);
            }}
            rows={4}
            maxLength={ADMIN_RESOLUTION_NOTES_MAX}
            placeholder={
              needsNotes
                ? 'مطلوب عند تم الحل أو رفض البلاغ'
                : 'اختياري عند قيد المراجعة'
            }
            className="w-full border rounded-lg px-3 py-2 text-sm"
          />
          <p className="text-xs text-gray-500 mt-1 text-left">
            {notes.length}/{ADMIN_RESOLUTION_NOTES_MAX}
          </p>
        </div>

        {error && <p className="text-sm text-red-600">{error}</p>}
        {sameStatus && (
          <p className="text-xs text-amber-700">اختر حالة مختلفة عن الحالة الحالية</p>
        )}
      </div>
    </FormModal>
  );
}
