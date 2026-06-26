/// Paths that must not send `Authorization` (anonymous / bootstrap / catalog).
/// Keep aligned with CleaningHouse Swagger (`/swagger`).
class PublicApiPaths {
  PublicApiPaths._();

  static const _exact = <String>{
    '/api/AppUsers/Login',
    '/api/AppUsers/SocialLoginCustomer',
    '/api/AppUsers/ForgotPassword',
    '/api/AppUsers/VerifyResetCode',
    '/api/AppUsers/ResetPassword',
    '/api/AppUsers/CreateNewCustomer',
    '/api/AppUsers/CreateNewCompanyOwner',
    '/api/AppUsers/CreateNewAdmin',
    '/api/Cities/GetAllCities',
    '/api/Languages/GetAllLanguages',
    '/api/Workers/Available',
    '/api/v1/workers/available',
    '/api/v1/workers/top-rated',
    '/api/Companies/GetisVerifiedCompanies',
    '/api/WorkTypes/GetAllWorkTypes',
  };

  static bool isPublicPath(String pathOrUrl) {
    final path = _normalize(pathOrUrl);
    if (_exact.contains(path)) return true;
    if (path.startsWith('/api/Companies/GetCompanyById/')) return true;
    if (path.startsWith('/api/Workers/GetWorkerById/')) return true;
    if (path.startsWith('/api/WorkTypes/GetWorkerWorkTypes/')) return true;
    if (path.startsWith('/api/WorkTypes/GetWorkTypesByCompany/')) return true;
    if (path.startsWith('/api/Reviews/Worker/')) return true;
    if (path.startsWith('/api/Reviews/Company/')) return true;
    return false;
  }

  static String _normalize(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Uri.parse(pathOrUrl).path;
    }
    return pathOrUrl.split('?').first;
  }
}
