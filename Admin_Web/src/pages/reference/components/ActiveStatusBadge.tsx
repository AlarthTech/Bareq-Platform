export function ActiveStatusBadge({ isActive }: { isActive: boolean }) {
  return (
    <span
      className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${
        isActive ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'
      }`}
    >
      {isActive ? 'نشط' : 'معطل'}
    </span>
  );
}
