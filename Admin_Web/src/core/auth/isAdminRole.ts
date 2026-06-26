export function isAdminRole(userTypeName?: string | null): boolean {
  return userTypeName?.toLowerCase() === 'admin';
}
