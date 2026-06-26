export function buildFileUrl(relativePath?: string | null): string | null {
  if (!relativePath) return null;
  if (!/^\/uploads\//i.test(relativePath)) return null;
  return relativePath.replace(/^\/uploads\//i, '/uploads/');
}
