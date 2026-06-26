/// App string constants
/// All user-facing strings should be defined here for easy management and localization
class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'Bareq';

  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String search = 'Search';
  static const String available = 'Available';

  // Greetings
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String greetingMicroCopy = 'Let\'s find the right help for today';

  // Home Screen
  static const String searchPlaceholder = 'Search maids, companies, skills…';
  static const String findAvailableMaids = 'Find Available Maids';
  static const String availableToday = 'Available Today';
  static const String topRatedMaids = 'Top Rated Maids';
  static const String viewAll = 'View All';

  // Service Categories
  static const String dailyCleaning = 'Daily Cleaning';
  static const String weeklyCleaning = 'Weekly Cleaning';
  static const String deepCleaning = 'Deep Cleaning';
  static const String postConstruction = 'Post-construction';

  // CTA
  static const String companyJoinSitt = 'Are you a company? Join Bareq';
  static const String sponsored = 'Sponsored';

  // Default City
  static const String defaultCity = 'Tripoli';

  // Routes
  static const String routeHome = '/home';
  static const String routeAdminHome = '/admin-home';
  static const String routeCompanyHome = '/company-home';
  static const String routeLogin = '/login';
  static const String routeCompleteProfile = '/complete-profile';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeVerifyResetCode = '/verify-reset-code';
  static const String routeResetPassword = '/reset-password';
  static const String routeRegistration = '/registration';
  static const String routeSplash = '/';
  static const String routeSearch = '/search';
  static const String routeSearchResults = '/search-results';
  static const String routeCompanies = '/companies';
  static const String routeBookings = '/bookings';
  static const String routeFavorites = '/favorites';
  static const String routeProfile = '/profile';
  static const String routeEditProfile = '/profile/edit';
  static const String routeNotificationsSettings = '/profile/notifications';
  static const String routePrivacySecurity = '/profile/privacy';
  static const String routeChangePhone = '/profile/change-phone';
  static const String routeChangePassword = '/profile/change-password';
  static const String routeHelpSupport = '/profile/help';
  static const String routeAboutBareq = '/profile/about';
  static const String routePrivacyPolicy = '/profile/privacy-policy';
  static const String routeTermsConditions = '/profile/terms';
  static const String routeSavedLocations = '/profile/locations';
  static const String routeAddLocation = '/profile/locations/add';
  static const String routeEditLocation = '/profile/locations/:id/edit';
  static String editLocationRoute(String id) => '/profile/locations/$id/edit';
  static const String routeMaidDetails = '/maid/:id';
  static String maidDetailsRoute(String id) => '/maid/$id';
  static const String routeCompanyDetails = '/company/:id';
  static String companyDetailsRoute(String id) => '/company/$id';
  static const String routeBooking = '/booking/:maidId';
  static String bookingRoute(String maidId) => '/booking/$maidId';
  static const String routeBookingDetails = '/booking-details/:bookingId';
  static String bookingDetailsRoute(String bookingId) => '/booking-details/$bookingId';

  static const String routeCreateReport = '/reports/create';
  static const String routeMyReports = '/reports/my';
  static const String routeReportDetail = '/reports/:id';
  static String reportDetailRoute(int id) => '/reports/$id';

  static const String routeCreateBookingReport = '/booking-reports/create';
  static const String routeMyBookingReports = '/booking-reports/my';
  static const String routeBookingReportsByBooking =
      '/booking-reports/booking/:bookingId';
  static String bookingReportsByBookingRoute(int bookingId) =>
      '/booking-reports/booking/$bookingId';
  static const String routeBookingReportDetail = '/booking-reports/detail/:id';
  static String bookingReportDetailRoute(int id) =>
      '/booking-reports/detail/$id';

  static const String routeRateWorker = '/reviews/rate';
  static const String routeMyReview = '/reviews/booking/:bookingId';
  static String myReviewRoute(int bookingId) => '/reviews/booking/$bookingId';

  static const String routeNotifications = '/notifications';

  static const String routeWallet = '/wallet';
  static const String routeWalletTopUp = '/wallet/top-up';
  static const String routeWalletBankTransferTopUp = '/wallet/top-up/transfer';
  static const String routeWalletTransactions = '/wallet/transactions';
  static const String routeWalletTopUpStatus = '/wallet/top-up/:id';
  static String walletTopUpStatusRoute(String id) => '/wallet/top-up/$id';

  // Navigation
  static const String navHome = 'Home';
  static const String navSearch = 'Search';
  static const String navBookings = 'Bookings';
  static const String navFavorites = 'Favorites';
  static const String navProfile = 'Profile';

  // Common UI
  static const String join = 'Join';
  static const String selectDate = 'Select Date';
  static const String today = 'Today';
  static const String tomorrow = 'Tomorrow';
  static const String services = 'Services';

  // Search Screen
  static const String searchMaidsCompanies = 'Search maids, companies...';
  static const String filters = 'Filters';
  static const String applyFilters = 'Apply Filters';
  static const String clearFilters = 'Clear Filters';
  static const String clearAll = 'Clear all';
  static const String searchResults = 'Search Results';
  static const String resultsFound = 'results found';
  static const String noResultsFound = 'No results found';
  static const String tryDifferentFilters = 'Try adjusting your filters';
  static const String activeFilters = 'Active Filters';
  static const String service = 'Service';
  
  // Companies
  static const String companies = 'Companies';
  static const String findTrustedCompanies = 'Find trusted cleaning companies';
  static const String noCompaniesFound = 'No companies found';
  static const String checkBackLater = 'Check back later for new companies';
  static const String maids = 'maids';
  static const String navCompanies = 'Companies';
  static const String searchCompanies = 'Search companies...';
  static const String companyFound = 'company found';
  static const String companiesFound = 'companies found';
  static const String verification = 'Verification';
  static const String verified = 'Verified';
  static const String verifiedOnly = 'Verified Only';
  static const String featured = 'Featured';
  static const String ourMaids = 'Our Maids';
  static const String reviews = 'reviews';
  static const String contactInformation = 'Contact Information';
  static const String yearsInBusiness = 'Years in Business';
  static const String noMaidsAvailable = 'No maids available for this company';
  static const String companyNotFound = 'Company not found';

  // Booking Screen
  static const String bookNow = 'Book Now';
  static const String bookingType = 'Booking Type';
  static const String singleDay = 'Single Day';
  static const String overnight = 'Overnight';
  static const String bookingReason = 'Booking Reason';
  static const String normalDailyCleaning = 'Normal Daily Cleaning';
  static const String occasion = 'Occasion';
  static const String confirmBooking = 'Confirm Booking';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String step = 'Step';
  static const String of = 'of';
  static const String shift = 'Shift';
  static const String morning = 'Morning';
  static const String afternoon = 'Afternoon';
  static const String evening = 'Evening';
  static const String bookingSummary = 'Booking Summary';
  static const String selectedDate = 'Selected Date';
  static const String totalPrice = 'Total Price';
  static const String bookingStatus = 'Booking Status';
  static const String editBooking = 'Edit Booking';
  static const String cancelBooking = 'Cancel Booking';
  static const String all = 'All';
  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String completed = 'Completed';
  static const String waitingForConfirmation = 'Waiting for the company to confirm your booking';
  static const String companyContact = 'Company Contact';
  static const String workingHours = 'Working Hours';
  static const String location = 'Location';
  static const String phoneNumber = 'Phone Number';
  
  // Settings Screen
  static const String settings = 'Settings';
  static const String changeLanguage = 'Change Language';
  static const String account = 'Account';
  static const String editProfile = 'Edit Profile';
  static const String notifications = 'Notifications';
  static const String privacyAndSecurity = 'Privacy & Security';
  static const String support = 'Support';
  static const String helpAndSupport = 'Help & Support';
  static const String about = 'About';
  static const String termsAndConditions = 'Terms & Conditions';
  static const String logout = 'Logout';
  static const String myBookings = 'My Bookings';
  
  // Maid Details Screen
  static const String maidNotFound = 'Maid not found';
  static const String goHome = 'Go Home';
  static const String upcoming = 'Upcoming';
  static const String past = 'Past';
  static const String maid = 'Maid';
  static const String date = 'Date';
  static const String time = 'Time';
  static const String language = 'Language';
  static const String availability = 'Availability';
  static const String thisWeek = 'This Week';
  static const String rating = 'Rating';
  static const String minimumRating = 'Minimum Rating';
  static const String andAbove = 'and above';
  static const String experience = 'Experience';
  static const String city = 'City';
  static const String years = 'years';
  
  // Languages
  static const String arabic = 'Arabic';
  static const String english = 'English';
  static const String french = 'French';
  
  // Cities (Libyan cities)
  static const String tripoli = 'Tripoli';
  static const String benghazi = 'Benghazi';
  static const String misrata = 'Misrata';
  static const String sabha = 'Sabha';
}

