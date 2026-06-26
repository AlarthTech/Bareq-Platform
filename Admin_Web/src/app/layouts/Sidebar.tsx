import { useState, useEffect, type ReactNode } from 'react';
import { NavLink, useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Building2,
  Calendar,
  UserCog,
  Briefcase,
  Star,
  Heart,
  Database,
  Settings,
  LogOut,
  Mail,
  ClipboardList,
  Shield,
  UserCircle,
  Users,
  Wallet,
  CircleDollarSign,
  Banknote,
  Flag,
  CalendarClock,
  MapPin,
  Globe2,
  Languages,
  Sparkles,
  PanelRightClose,
  PanelRightOpen,
  ChevronDown,
  type LucideIcon,
} from 'lucide-react';
import { usePlatformFee } from '../../features/platform-fee/hooks/usePlatformFee';
import { usePendingBankTransferCount } from '../../features/wallet/hooks/useWalletTopUps';
import { useOpenBookingReportsCount } from '../../hooks/useBookingReports';
import { formatLyd } from '../../core/utils';
import { useQuery } from '@tanstack/react-query';
import { ROUTES } from '../../core/constants';
import { classNames } from '../../core/utils';
import { useAuthStore } from '../../core/auth/store';
import { companiesApi } from '../../api/companies.api';
import { usePendingReportsCount } from '../../hooks/useReports';

const mainNav = [
  { name: 'لوحة التحكم', href: ROUTES.DASHBOARD, icon: LayoutDashboard },
  { name: 'الشركات', href: ROUTES.COMPANIES, icon: Building2 },
  { name: 'طلبات التحقق', href: ROUTES.COMPANIES_PENDING, icon: ClipboardList, badgeKey: 'pending' as const },
  { name: 'الحجوزات', href: ROUTES.BOOKINGS, icon: Calendar },
  { name: 'العاملات', href: ROUTES.WORKERS, icon: UserCog },
  { name: 'أنواع العمل', href: ROUTES.WORK_TYPES, icon: Briefcase },
  { name: 'التقييمات', href: ROUTES.REVIEWS, icon: Star },
  { name: 'المفضلة', href: ROUTES.FAVORITES, icon: Heart },
];

const usersNav = [
  { name: 'المديرون', href: ROUTES.USERS.ADMINS, icon: Shield },
  { name: 'أصحاب الشركات', href: ROUTES.USERS.COMPANY_OWNERS, icon: Building2 },
  { name: 'العملاء', href: ROUTES.USERS.CUSTOMERS, icon: UserCircle },
];

const refNav = [
  { name: 'المدن', href: ROUTES.REFERENCE.CITIES, icon: MapPin },
  { name: 'الجنسيات', href: ROUTES.REFERENCE.NATIONALITIES, icon: Globe2 },
  { name: 'اللغات', href: ROUTES.REFERENCE.LANGUAGES, icon: Languages },
  { name: 'خدمات التنظيف', href: ROUTES.REFERENCE.CLEANING_SERVICES, icon: Sparkles },
];

const financeNav = [
  { name: 'رسوم المنصة', href: ROUTES.PLATFORM_FEE, icon: CircleDollarSign, subtitleKey: 'platformFee' as const },
  { name: 'إعدادات المحفظة', href: ROUTES.WALLET_SETTINGS, icon: Wallet },
  { name: 'طلبات شحن المحفظة', href: ROUTES.WALLET_TOP_UPS, icon: Banknote, badgeKey: 'topUp' as const },
];

const operationsNav = [
  { name: 'بلاغات العملاء', href: ROUTES.REPORTS, icon: Flag, badgeKey: 'reports' as const },
  {
    name: 'بلاغات الحجوزات',
    href: ROUTES.BOOKING_REPORTS,
    icon: CalendarClock,
    badgeKey: 'bookingReports' as const,
  },
];

type SidebarSectionId = 'main' | 'users' | 'reference' | 'finance' | 'operations';

const SIDEBAR_SECTION_IDS: SidebarSectionId[] = [
  'main',
  'users',
  'reference',
  'finance',
  'operations',
];

const OPEN_SECTION_KEY = 'bareq.sidebar.openSection';
const DEFAULT_OPEN_SECTION: SidebarSectionId = 'main';

function readOpenSection(): SidebarSectionId {
  try {
    const stored = localStorage.getItem(OPEN_SECTION_KEY);
    if (stored && SIDEBAR_SECTION_IDS.includes(stored as SidebarSectionId)) {
      return stored as SidebarSectionId;
    }
  } catch {
    // ignore storage errors
  }
  return DEFAULT_OPEN_SECTION;
}

function sectionForPath(pathname: string): SidebarSectionId | null {
  if (pathname.startsWith(ROUTES.USERS.BASE)) return 'users';
  if (pathname.startsWith(ROUTES.REFERENCE.BASE)) return 'reference';
  if (
    pathname.startsWith(ROUTES.PLATFORM_FEE) ||
    pathname.startsWith(ROUTES.WALLET_SETTINGS) ||
    pathname.startsWith(ROUTES.WALLET_BANK_ACCOUNTS) ||
    pathname.startsWith(ROUTES.WALLET_TOP_UPS) ||
    pathname.startsWith(ROUTES.WALLET_MANUAL_CREDIT)
  ) {
    return 'finance';
  }
  if (pathname.startsWith(ROUTES.REPORTS) || pathname.startsWith(ROUTES.BOOKING_REPORTS)) {
    return 'operations';
  }
  if (
    pathname === ROUTES.DASHBOARD ||
    pathname.startsWith(ROUTES.COMPANIES) ||
    pathname.startsWith(ROUTES.BOOKINGS) ||
    pathname.startsWith(ROUTES.WORKERS) ||
    pathname.startsWith(ROUTES.WORK_TYPES) ||
    pathname.startsWith(ROUTES.REVIEWS) ||
    pathname.startsWith(ROUTES.FAVORITES)
  ) {
    return 'main';
  }
  return null;
}

interface SidebarNavItemProps {
  href: string;
  label: string;
  icon: LucideIcon;
  collapsed: boolean;
  badge?: number;
  subtitle?: string;
  onNavigate?: () => void;
}

function SidebarNavItem({
  href,
  label,
  icon: Icon,
  collapsed,
  badge,
  subtitle,
  onNavigate,
}: SidebarNavItemProps) {
  const showBadge = badge != null && badge > 0;

  return (
    <NavLink
      to={href}
      onClick={onNavigate}
      title={collapsed ? label : undefined}
      className={({ isActive }) =>
        classNames(
          'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
          collapsed ? 'justify-center' : '',
          isActive ? 'bg-bareq-50 text-bareq-700' : 'text-gray-700 hover:bg-gray-50'
        )
      }
    >
      <span className="relative shrink-0">
        <Icon className="w-5 h-5" />
        {collapsed && showBadge && (
          <span className="absolute -top-1 -left-1 w-2 h-2 bg-bareq-600 rounded-full ring-2 ring-white" />
        )}
      </span>
      {!collapsed && (
        <>
          <span className="flex-1 min-w-0">
            <span className="block">{label}</span>
            {subtitle && (
              <span className="block text-xs text-gray-500 font-normal truncate">{subtitle}</span>
            )}
          </span>
          {showBadge && (
            <span className="bg-bareq-600 text-white text-xs px-2 py-0.5 rounded-full shrink-0">
              {badge}
            </span>
          )}
        </>
      )}
    </NavLink>
  );
}

interface SidebarSectionProps {
  id: SidebarSectionId;
  title: string;
  icon: LucideIcon;
  collapsed: boolean;
  isOpen: boolean;
  onToggle: (id: SidebarSectionId) => void;
  children: ReactNode;
}

function SidebarSection({
  id,
  title,
  icon: SectionIcon,
  collapsed,
  isOpen,
  onToggle,
  children,
}: SidebarSectionProps) {
  if (collapsed) {
    return <div className="space-y-1">{children}</div>;
  }

  return (
    <div className="pt-2">
      <button
        type="button"
        onClick={() => onToggle(id)}
        className={classNames(
          'flex items-center gap-2 w-full px-3 py-2 text-xs font-semibold rounded-lg transition-colors',
          isOpen ? 'text-bareq-700 bg-bareq-50' : 'text-gray-400 hover:text-gray-600 hover:bg-gray-50'
        )}
        aria-expanded={isOpen}
        aria-controls={`sidebar-section-${id}`}
      >
        <SectionIcon className="w-4 h-4 shrink-0" />
        <span className="flex-1 text-right">{title}</span>
        <ChevronDown
          className={classNames('w-4 h-4 shrink-0 transition-transform duration-200', isOpen && 'rotate-180')}
        />
      </button>
      <div
        id={`sidebar-section-${id}`}
        className={classNames(
          'grid transition-[grid-template-rows] duration-200 ease-in-out',
          isOpen ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'
        )}
      >
        <div className="overflow-hidden">
          <div className="space-y-1 mr-1 mt-0.5">{children}</div>
        </div>
      </div>
    </div>
  );
}

interface SidebarProps {
  collapsed: boolean;
  setCollapsed: (v: boolean) => void;
  mobileOpen?: boolean;
  onMobileClose?: () => void;
}

export function Sidebar({ collapsed, setCollapsed, mobileOpen = false, onMobileClose }: SidebarProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { logout } = useAuthStore();

  const [openSection, setOpenSection] = useState<SidebarSectionId | null>(() => {
    const fromPath = sectionForPath(window.location.pathname);
    return fromPath ?? readOpenSection();
  });

  useEffect(() => {
    const section = sectionForPath(location.pathname);
    if (section) setOpenSection(section);
  }, [location.pathname]);

  useEffect(() => {
    try {
      if (openSection) {
        localStorage.setItem(OPEN_SECTION_KEY, openSection);
      }
    } catch {
      // ignore storage errors
    }
  }, [openSection]);

  const toggleSection = (id: SidebarSectionId) => {
    setOpenSection((current) => (current === id ? null : id));
  };

  const { data: pendingData } = useQuery({
    queryKey: ['companies', 'pending-count'],
    queryFn: () => companiesApi.getAll({ page: 1, pageSize: 50 }),
    select: (d) => d.items.filter((c) => !c.isVerified).length,
  });

  const { data: pendingReports = 0 } = usePendingReportsCount();
  const { data: openBookingReports = 0 } = useOpenBookingReportsCount();
  const { data: platformFee } = usePlatformFee();
  const { data: pendingBankTransfers = 0 } = usePendingBankTransferCount();

  const pendingCount = pendingData ?? 0;
  const platformFeeLabel =
    platformFee != null ? formatLyd(platformFee.fixedPlatformFeeAmount) : null;

  const widthCollapsed = collapsed && !mobileOpen;

  const handleNavigate = () => {
    onMobileClose?.();
  };

  const getBadge = (key?: 'pending' | 'topUp' | 'reports' | 'bookingReports') => {
    if (key === 'pending') return pendingCount;
    if (key === 'topUp') return pendingBankTransfers;
    if (key === 'reports') return pendingReports;
    if (key === 'bookingReports') return openBookingReports;
    return undefined;
  };

  return (
    <>
      {mobileOpen && (
        <button
          type="button"
          aria-label="إغلاق القائمة"
          className="fixed inset-0 bg-black/40 z-40 md:hidden"
          onClick={onMobileClose}
        />
      )}

      <aside
        className={classNames(
          'bg-white border-l border-gray-200 h-screen fixed right-0 top-0 z-50 sidebar-transition flex flex-col',
          widthCollapsed ? 'w-16' : 'w-64',
          'max-md:translate-x-full max-md:w-64',
          mobileOpen && 'max-md:translate-x-0'
        )}
      >
        <div
          className={classNames(
            'flex items-center h-16 px-3 border-b border-gray-200 shrink-0',
            widthCollapsed ? 'justify-center' : 'justify-between px-4'
          )}
        >
          {!widthCollapsed && (
            <div>
              <h1 className="text-lg font-bold text-bareq-600">برق</h1>
              <p className="text-xs text-gray-500">لوحة الإدارة</p>
            </div>
          )}
          <button
            type="button"
            onClick={() => setCollapsed(!collapsed)}
            className={classNames('p-2 rounded-lg hover:bg-gray-100', widthCollapsed && 'mx-auto')}
            aria-label={collapsed ? 'توسيع القائمة' : 'طي القائمة'}
            aria-expanded={!collapsed}
          >
            {collapsed ? (
              <PanelRightOpen className="w-5 h-5 text-gray-600" />
            ) : (
              <PanelRightClose className="w-5 h-5 text-gray-600" />
            )}
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto px-2 py-4 space-y-1">
          <SidebarSection
            id="main"
            title="الرئيسية"
            icon={LayoutDashboard}
            collapsed={widthCollapsed}
            isOpen={openSection === 'main'}
            onToggle={toggleSection}
          >
            {mainNav.map((item) => (
              <SidebarNavItem
                key={item.href}
                href={item.href}
                label={item.name}
                icon={item.icon}
                collapsed={widthCollapsed}
                badge={getBadge(item.badgeKey)}
                onNavigate={handleNavigate}
              />
            ))}
          </SidebarSection>

          <SidebarSection
            id="users"
            title="المستخدمون"
            icon={Users}
            collapsed={widthCollapsed}
            isOpen={openSection === 'users'}
            onToggle={toggleSection}
          >
            {usersNav.map((item) => (
              <SidebarNavItem
                key={item.href}
                href={item.href}
                label={item.name}
                icon={item.icon}
                collapsed={widthCollapsed}
                onNavigate={handleNavigate}
              />
            ))}
          </SidebarSection>

          <SidebarSection
            id="reference"
            title="البيانات المرجعية"
            icon={Database}
            collapsed={widthCollapsed}
            isOpen={openSection === 'reference'}
            onToggle={toggleSection}
          >
            {refNav.map((item) => (
              <SidebarNavItem
                key={item.href}
                href={item.href}
                label={item.name}
                icon={item.icon}
                collapsed={widthCollapsed}
                onNavigate={handleNavigate}
              />
            ))}
          </SidebarSection>

          <SidebarSection
            id="finance"
            title="المالية"
            icon={Wallet}
            collapsed={widthCollapsed}
            isOpen={openSection === 'finance'}
            onToggle={toggleSection}
          >
            {financeNav.map((item) => (
              <SidebarNavItem
                key={item.href}
                href={item.href}
                label={item.name}
                icon={item.icon}
                collapsed={widthCollapsed}
                badge={getBadge(item.badgeKey)}
                subtitle={
                  item.subtitleKey === 'platformFee' && platformFeeLabel ? platformFeeLabel : undefined
                }
                onNavigate={handleNavigate}
              />
            ))}
          </SidebarSection>

          <SidebarSection
            id="operations"
            title="العمليات"
            icon={ClipboardList}
            collapsed={widthCollapsed}
            isOpen={openSection === 'operations'}
            onToggle={toggleSection}
          >
            {operationsNav.map((item) => (
              <SidebarNavItem
                key={item.href}
                href={item.href}
                label={item.name}
                icon={item.icon}
                collapsed={widthCollapsed}
                badge={getBadge(item.badgeKey)}
                onNavigate={handleNavigate}
              />
            ))}
          </SidebarSection>

          <div className="pt-2 space-y-1">
            <SidebarNavItem
              href={ROUTES.SETTINGS}
              label="الإعدادات"
              icon={Settings}
              collapsed={widthCollapsed}
              onNavigate={handleNavigate}
            />
            <SidebarNavItem
              href={ROUTES.EMAIL_TEST}
              label="اختبار البريد"
              icon={Mail}
              collapsed={widthCollapsed}
              onNavigate={handleNavigate}
            />
          </div>
        </nav>

        <div className="border-t border-gray-200 p-2 shrink-0">
          <button
            type="button"
            onClick={() => {
              logout();
              navigate(ROUTES.LOGIN, { replace: true });
            }}
            title={widthCollapsed ? 'تسجيل الخروج' : undefined}
            className={classNames(
              'flex items-center gap-3 w-full px-3 py-2.5 rounded-lg text-sm font-medium text-red-600 hover:bg-red-50',
              widthCollapsed && 'justify-center'
            )}
          >
            <LogOut className="w-5 h-5 shrink-0" />
            {!widthCollapsed && 'تسجيل الخروج'}
          </button>
        </div>
      </aside>
    </>
  );
}
