/// Application roles from JWT (`role` / .NET role claim).
enum AppUserRole {
  admin,
  company,
  customer,
}

AppUserRole? appUserRoleFromClaim(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  switch (raw.trim().toLowerCase()) {
    case 'admin':
      return AppUserRole.admin;
    case 'company':
      return AppUserRole.company;
    case 'customer':
      return AppUserRole.customer;
    default:
      return null;
  }
}
