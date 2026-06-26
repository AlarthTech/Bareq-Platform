export const ROUTES = {
  LOGIN: '/login',
  SETUP: '/setup',
  DASHBOARD: '/dashboard',
  USERS: {
    BASE: '/users',
    ADMINS: '/users/admins',
    COMPANY_OWNERS: '/users/company-owners',
    CUSTOMERS: '/users/customers',
  },
  COMPANIES: '/companies',
  COMPANIES_PENDING: '/companies/pending',
  BOOKINGS: '/bookings',
  WORKERS: '/workers',
  WORK_TYPES: '/work-types',
  REVIEWS: '/reviews',
  REPORTS: '/reports',
  BOOKING_REPORTS: '/booking-reports',
  FAVORITES: '/favorites',
  REFERENCE: {
    BASE: '/reference',
    CITIES: '/reference/cities',
    NATIONALITIES: '/reference/nationalities',
    LANGUAGES: '/reference/languages',
    CLEANING_SERVICES: '/reference/cleaning-services',
  },
  SETTINGS: '/settings',
  PLATFORM_FEE: '/settings/platform-fee',
  WALLET_SETTINGS: '/settings/wallet',
  WALLET_BANK_ACCOUNTS: '/settings/wallet/bank-accounts',
  WALLET_TOP_UPS: '/wallet/top-ups',
  WALLET_MANUAL_CREDIT: '/wallet/manual-credit',
  EMAIL_TEST: '/system/email-test',
} as const;

export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 50,
  PAGE_SIZE_OPTIONS: [10, 20, 50],
} as const;

export const TOKEN_KEY = 'token';

/** Fixed commission deducted from company service price per booking (LYD). */
export const COMPANY_COMMISSION_PER_BOOKING_LYD = 5;
