import { createBrowserRouter, Navigate } from 'react-router-dom';
import { MainLayout } from './layouts/MainLayout';
import { ROUTES } from '../core/constants';
import { ProtectedRoute } from './components/ProtectedRoute';

import LoginPage from '../pages/LoginPage';
import SetupPage from '../pages/SetupPage';
import DashboardPage from '../pages/DashboardPage';
import AdminsPage from '../pages/users/AdminsPage';
import CompanyOwnersPage from '../pages/users/CompanyOwnersPage';
import CustomersPage from '../pages/users/CustomersPage';
import CompaniesListPage from '../pages/companies/CompaniesListPage';
import PendingCompaniesPage from '../pages/companies/PendingCompaniesPage';
import BookingsPage from '../pages/bookings/BookingsPage';
import BookingDetailPage from '../pages/bookings/BookingDetailPage';
import WorkersPage from '../pages/workers/WorkersPage';
import WorkTypesPage from '../pages/work-types/WorkTypesPage';
import ReviewsPage from '../pages/reviews/ReviewsPage';
import ReportsListPage from '../pages/reports/ReportsListPage';
import ReportDetailPage from '../pages/reports/ReportDetailPage';
import BookingReportsListPage from '../pages/booking-reports/BookingReportsListPage';
import BookingReportDetailPage from '../pages/booking-reports/BookingReportDetailPage';
import FavoritesPage from '../pages/favorites/FavoritesPage';
import CitiesPage from '../pages/reference/CitiesPage';
import NationalitiesPage from '../pages/reference/NationalitiesPage';
import LanguagesPage from '../pages/reference/LanguagesPage';
import CleaningServicesPage from '../pages/reference/CleaningServicesPage';
import SettingsPage from '../pages/settings/SettingsPage';
import PlatformFeeSettingsPage from '../features/platform-fee/pages/PlatformFeeSettingsPage';
import WalletSettingsPage from '../features/wallet/pages/WalletSettingsPage';
import WalletTopUpsPage from '../features/wallet/pages/WalletTopUpsPage';
import BankAccountsPage from '../features/wallet/pages/BankAccountsPage';
import WalletManualCreditPage from '../features/wallet/pages/WalletManualCreditPage';
import EmailTestPage from '../pages/system/EmailTestPage';

export const router = createBrowserRouter([
  { path: ROUTES.LOGIN, element: <LoginPage /> },
  { path: ROUTES.SETUP, element: <SetupPage /> },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <MainLayout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Navigate to={ROUTES.DASHBOARD} replace /> },
      { path: ROUTES.DASHBOARD, element: <DashboardPage /> },
      { path: ROUTES.USERS.BASE, element: <Navigate to={ROUTES.USERS.ADMINS} replace /> },
      { path: ROUTES.USERS.ADMINS, element: <AdminsPage /> },
      { path: ROUTES.USERS.COMPANY_OWNERS, element: <CompanyOwnersPage /> },
      { path: ROUTES.USERS.CUSTOMERS, element: <CustomersPage /> },
      { path: ROUTES.COMPANIES, element: <CompaniesListPage /> },
      { path: ROUTES.COMPANIES_PENDING, element: <PendingCompaniesPage /> },
      { path: ROUTES.BOOKINGS, element: <BookingsPage /> },
      { path: `${ROUTES.BOOKINGS}/:id`, element: <BookingDetailPage /> },
      { path: ROUTES.WORKERS, element: <WorkersPage /> },
      { path: ROUTES.WORK_TYPES, element: <WorkTypesPage /> },
      { path: ROUTES.REVIEWS, element: <ReviewsPage /> },
      { path: `${ROUTES.REPORTS}/:id`, element: <ReportDetailPage /> },
      { path: ROUTES.REPORTS, element: <ReportsListPage /> },
      { path: `${ROUTES.BOOKING_REPORTS}/:id`, element: <BookingReportDetailPage /> },
      { path: ROUTES.BOOKING_REPORTS, element: <BookingReportsListPage /> },
      { path: ROUTES.FAVORITES, element: <FavoritesPage /> },
      { path: ROUTES.REFERENCE.CITIES, element: <CitiesPage /> },
      { path: ROUTES.REFERENCE.NATIONALITIES, element: <NationalitiesPage /> },
      { path: ROUTES.REFERENCE.LANGUAGES, element: <LanguagesPage /> },
      { path: ROUTES.REFERENCE.CLEANING_SERVICES, element: <CleaningServicesPage /> },
      { path: ROUTES.SETTINGS, element: <SettingsPage /> },
      { path: ROUTES.PLATFORM_FEE, element: <PlatformFeeSettingsPage /> },
      { path: ROUTES.WALLET_SETTINGS, element: <WalletSettingsPage /> },
      { path: ROUTES.WALLET_BANK_ACCOUNTS, element: <BankAccountsPage /> },
      { path: ROUTES.WALLET_TOP_UPS, element: <WalletTopUpsPage /> },
      { path: ROUTES.WALLET_MANUAL_CREDIT, element: <WalletManualCreditPage /> },
      { path: ROUTES.EMAIL_TEST, element: <EmailTestPage /> },
    ],
  },
]);
