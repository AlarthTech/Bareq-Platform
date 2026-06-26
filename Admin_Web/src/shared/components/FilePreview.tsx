import { ExternalLink, FileText } from 'lucide-react';
import { buildFileUrl } from '../../core/utils';

interface FilePreviewProps {
  url?: string | null;
  label?: string;
}

export function FilePreview({ url, label = 'عرض الملف' }: FilePreviewProps) {
  const fileUrl = buildFileUrl(url);
  if (!fileUrl) {
    return <span className="text-gray-400 text-sm">لا يوجد ملف</span>;
  }

  const isPdf = fileUrl.toLowerCase().endsWith('.pdf');
  const isImage = /\.(jpg|jpeg|png|webp)$/i.test(fileUrl);

  return (
    <div className="space-y-2">
      {isImage && (
        <img src={fileUrl} alt={label} className="max-h-48 rounded-lg border border-gray-200" />
      )}
      {isPdf && (
        <div className="flex items-center gap-2 text-sm text-gray-600">
          <FileText className="w-4 h-4" />
          <span>ملف PDF</span>
        </div>
      )}
      <a
        href={fileUrl}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-1 text-sm text-rose-600 hover:text-rose-700"
      >
        <ExternalLink className="w-4 h-4" />
        {label}
      </a>
    </div>
  );
}
