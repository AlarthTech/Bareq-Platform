import { REPORT_STATUS_COLORS, REPORT_STATUS_LABELS } from '../../types/report.types';

export function ReportStatusBadge({ status, label }: { status: number; label?: string }) {
  const text = label ?? REPORT_STATUS_LABELS[status] ?? 'غير معروف';
  const color = REPORT_STATUS_COLORS[status] ?? 'bg-gray-100 text-gray-800';
  return (
    <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${color}`}>
      {text}
    </span>
  );
}
