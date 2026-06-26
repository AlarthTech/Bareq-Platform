# Bareq Admin Dashboard — Full Front-End Implementation Prompt

Copy everything below the line into Cursor / your **Admin Dashboard** web front-end agent.

---

## PROMPT START

You are building the **Bareq Admin Dashboard** — a production web application for platform administrators to manage users, companies, bookings, workers, reviews, and reference data for the **CleaningHouse / Bareq** platform.

**Recommended stack:** React 18+ · TypeScript · Vite · React Router · TanStack Query · Axios (or fetch) · Tailwind CSS · shadcn/ui (or Ant Design) · RTL Arabic support

**API Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Health:** `GET /health`

The dashboard is **Admin-only**. All data comes from the existing ASP.NET Core 9 REST API — do not mock endpoints in production.

---

## 1. Authentication

### Login

```http
POST /api/AppUsers/Login
Content-Type: application/json
```

```json
{
  "username": "admin@albareq.ly",
  "password": "YourPassword",
  "userType": "Admin"
}
```

- `username` = email **or** phone
- **Must** send `"userType": "Admin"`

**Success (200):**

```json
{
  "success": true,
  "message": "تم تسجيل الدخول بنجاح",
  "token": "eyJ...",
  "user": {
    "id": 1,
    "fullName": "...",
    "phone": "...",
    "email": "...",
    "userTypeId": 1,
    "userTypeName": "Admin",
    "createdAt": "2026-05-31T..."
  }
}
```

**Failure:** `401` with `{ success: false, message: "..." }`

### Token storage

- Store JWT in `localStorage` or `sessionStorage` (or httpOnly cookie if you add a BFF later)
- Attach to every protected request:

```
Authorization: Bearer {token}
```

- Default JWT expiry: **24 hours**
- On **401** → clear token → redirect to `/login`
- On **403** → show "لا تملك صلاحية" (wrong role)

### Auth guard

After login, verify `user.userTypeName === "Admin"`. If not Admin, logout immediately.

### Bootstrap admin (first-time only)

```http
POST /api/AppUsers/CreateNewAdmin
Content-Type: application/json
```

Body: `{ fullName, phone, email, password, cityId? }`

- **Open** if no active admin exists in DB
- **Requires Admin JWT** once an admin already exists
- Show this only on a `/setup` route when API returns 403 on login and no admin exists

### Admin profile (logged in)

| Method | Path | Body |
|--------|------|------|
| PUT | `/api/AppUsers/ChangePassword` | `{ currentPassword, newPassword }` |
| PUT | `/api/AppUsers/ChangePersonalInfo` | `{ fullName, email }` |
| PUT | `/api/AppUsers/ChangePhoneNumber` | `{ phone }` |

---

## 2. Global API conventions

### Pagination — CRITICAL

All admin list endpoints return **`PagedResult<T>`**, never a root array.

```json
{
  "items": [ /* T[] */ ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 142,
  "totalPages": 8,
  "hasNextPage": true,
  "hasPreviousPage": false
}
```

Query params: `?page=1&pageSize=20` (max **50**, default **20**)

```typescript
interface PagedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}
```

Build a reusable `<DataTable />` with page controls using `hasNextPage` / `hasPreviousPage`.

### HTTP status codes

| Code | Action |
|------|--------|
| 200 | Success (may include body) |
| 201 | Created — use `Location` or response body id |
| 204 | Success, no body (updates/deletes) |
| 400 | Show API `message` or validation errors (often Arabic string) |
| 401 | Redirect to login |
| 403 | Permission denied toast |
| 404 | Not found page/state |
| 409 | Conflict (bookings) — show message |
| 429 | Rate limit — friendly Arabic retry message |

### File uploads

- **Content-Type:** `multipart/form-data`
- Field name: **`file`**
- Max size: **10 MB**
- Do **not** set `Content-Type` manually — browser sets boundary
- Static files URL: `{baseUrl}{relativePath}` e.g.  
  `http://102.203.200.55:5545/Uploads/CommercialRegister/company_11_20260531120000.pdf`

### API client (Axios example)

```typescript
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? 'http://102.203.200.55:5545',
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);
```

---

## 3. App layout & navigation

### Shell structure

```
/login
/setup                    (bootstrap admin — optional)
/dashboard                (stats overview)
/users
/companies
/companies/pending        (verification queue)
/bookings
/workers
/work-types
/reviews
/favorites
/reference/cities
/reference/nationalities
/reference/languages
/reference/cleaning-services
/settings                 (admin profile)
/system/email-test
```

### Sidebar (Arabic RTL)

| Menu | Icon hint | Route |
|------|-----------|-------|
| لوحة التحكم | Dashboard | `/dashboard` |
| المستخدمون | Users | `/users` |
| الشركات | Companies | `/companies` |
| طلبات التحقق | Pending badge | `/companies/pending` |
| الحجوزات | Bookings | `/bookings` |
| العاملات | Workers | `/workers` |
| أنواع العمل | Work types | `/work-types` |
| التقييمات | Reviews | `/reviews` |
| المفضلة | Favorites | `/favorites` |
| البيانات المرجعية | Reference | submenu |
| إعدادات | Settings | `/settings` |

- **RTL** layout (`dir="rtl"`, Arabic font e.g. Cairo / Tajawal)
- Responsive: collapsible sidebar on mobile
- Top bar: admin name, logout, optional dark mode

### Dashboard home (summary cards)

Fetch counts from paginated endpoints with `pageSize=1` and use `totalCount`:

- Total users → `GET /api/AppUsers/GetAllAppUsers?page=1&pageSize=1`
- Total companies → `GET /api/Companies/GetAllCompanies?page=1&pageSize=1`
- Pending verification → filter client-side `isVerified === false` or dedicated pending view
- Total bookings → `GET /api/Bookings/GetBookings?page=1&pageSize=1`
- Total workers → `GET /api/Workers/GetWorkers?page=1&pageSize=1`

---

## 4. Module: Users

### List (Admin only)

```http
GET /api/AppUsers/GetAllAppUsers?page=1&pageSize=20
Authorization: Bearer {token}
```

**Response item (`AppUserDTO`):**

```typescript
interface AppUser {
  id: number;
  fullName: string;
  phone: string;
  email: string;
  userTypeId: number;
  userTypeName: 'Admin' | 'Company' | 'Customer' | string;
  createdAt: string;
}
```

**Table columns:** ID, الاسم, البريد, الهاتف, نوع المستخدم, تاريخ التسجيل, إجراءات

**Filters (client-side):** by `userTypeName` (Admin / Company / Customer)

### Detail

```http
GET /api/AppUsers/GetAppUserById/{id}
```

### Update

```http
PATCH /api/AppUsers/UpdateAppUser/{id}
Content-Type: application/json
```

```json
{
  "fullName": "...",
  "phone": "...",
  "email": "...",
  "password": "newOptionalPassword"
}
```

Returns **204**. Validate unique email/phone (400 on conflict).

### Soft delete

```http
DELETE /api/AppUsers/DeleteAppUser/{id}
```

Returns **204** — sets `IsActive = false` (user disappears from list).

### Create admin

```http
POST /api/AppUsers/CreateNewAdmin
```

Body: `{ fullName, phone, email, password, cityId? }`

### Create company owner / customer (support actions)

| Endpoint | Purpose |
|----------|---------|
| `POST /api/AppUsers/CreateNewCompanyOwner` | Manual company owner |
| `POST /api/AppUsers/CreateNewCustomer` | Manual customer (sends welcome email) |

Both are `[AllowAnonymous]` but useful from admin forms.

---

## 5. Module: Companies (core admin workflow)

### List all companies (Admin only)

```http
GET /api/Companies/GetAllCompanies?page=1&pageSize=20
```

**Response item (`CompanyDTO`):**

```typescript
interface Company {
  id: number;
  name: string;
  address?: string;
  commercialRegNo?: string;
  commercialRegisterURL?: string;
  phone: string;
  email: string;
  ownerUserId: number;
  ownerUserName?: string;
  cityId: number;
  cityName?: string;
  experienceYears: number;
  description?: string;
  isVerified: boolean;
  createdAt: string;
}
```

> **API gap:** `isActive` is **not** in DTO. Track active state from toggle endpoint responses or list refresh after toggle.

**Table columns:** ID, اسم الشركة, المالك, المدينة, الهاتف, موثقة؟, السجل التجاري, تاريخ الإنشاء, إجراءات

### Pending verification queue

Route: `/companies/pending`

Filter: `isVerified === false`

Show badge count in sidebar.

### Company detail drawer/page

Use data from list row. For commercial register:

```typescript
const fileUrl = company.commercialRegisterURL
  ? `${API_BASE}${company.commercialRegisterURL}`
  : null;
```

- PDF → embed viewer or open in new tab
- Image → lightbox preview

> **Do NOT use** `GET /api/Companies/GetCompanyById/{id}` for admin review — it only returns **verified + active** companies. Use `GetAllCompanies` data.

### Approve / verify company (Admin only)

```http
PATCH /api/Companies/UpdateCompanyisVerified/{id}
```

No body. **Toggles both `isVerified` AND `isActive` together.**

Response:

```json
{ "message": "تم تحديث حالة IsVerified بنجاح", "isVerified": true }
```

**UI copy:** "الموافقة على الشركة" / "إلغاء التوثيق" — warn admin that this also toggles active status.

### Toggle active only

```http
PATCH /api/Companies/UpdateCompanyIsActive/{id}
```

Response: `{ message, isActive }`

### Update company details

```http
PATCH /api/Companies/UpdateCompany/{id}
```

```json
{
  "name": "...",
  "address": "...",
  "commercialRegNo": "...",
  "email": "...",
  "cityId": 1,
  "experienceYears": 5,
  "description": "..."
}
```

### Create company (on behalf of owner)

```http
POST /api/Companies/CreateCompany
```

```json
{
  "name": "...",
  "phone": "...",
  "email": "...",
  "ownerUserId": 10,
  "cityId": 1,
  "address": "...",
  "commercialRegNo": "...",
  "experienceYears": 0,
  "description": "..."
}
```

New companies default: `isVerified: false`, inactive until approved.

### Upload / replace commercial register

```http
POST /api/Companies/UploadCommercialRegister/{id}
POST /api/Companies/UpdateCommercialRegister/{id}
```

Multipart field `file` — PDF, JPG, JPEG, PNG — max 10MB.

### Soft delete

```http
DELETE /api/Companies/DeleteCompany/{id}
```

Sets `IsActive = false`, `IsVerified = false`.

### Admin approval UX flow

1. Open pending queue
2. View company details + commercial register file
3. Click **"اعتماد الشركة"** → `UpdateCompanyisVerified`
4. Company appears to customers via public APIs
5. Optional: deactivate later via `UpdateCompanyIsActive`

---

## 6. Module: Bookings

### List all (Admin only)

```http
GET /api/Bookings/GetBookings?page=1&pageSize=20
```

**Response item (`BookingDTO`):**

```typescript
interface Booking {
  id: number;
  userId: number;
  userName?: string;
  companyId: number;
  companyName?: string;
  workerId: number;
  workerName?: string;
  workTypeId: number;
  workTypeName?: string;
  bookingDate: string;
  startDate: string;      // time "HH:mm"
  endDate: string;
  address?: string;
  userLocationId?: number;
  locationName?: string;
  lat?: number;
  lng?: number;
  status: BookingStatus;
  rejectionReason?: string;
  servicePrice: number;
  platformFeeAmount: number;
  totalPrice: number;
  isMonthlyPricing: boolean;
  isWorkerArrivalConfirmed: boolean;
  workerArrivalConfirmedAt?: string | null;
  walletAmountReserved: boolean;
  walletAmountCaptured: boolean;
  walletCapturedAt?: string | null;
  createdAt: string;
}

enum BookingStatus {
  Pending = 0,
  Approved = 1,
  OnTheWay = 2,
  Completed = 3,
  Canceled = 4,
  Rejected = 5,
}
```

**Status badges (Arabic):**

| Value | Label | Color |
|-------|-------|-------|
| 0 | قيد الانتظار | yellow |
| 1 | مقبول | blue |
| 2 | في الطريق | purple |
| 3 | مكتمل | green |
| 4 | ملغي | gray |
| 5 | مرفوض | red |

### Detail

```http
GET /api/Bookings/GetBookingById/{id}
```

### Update status (Admin override)

```http
PATCH /api/Bookings/UpdateStatusBooking/{id}
```

```json
{
  "status": 3,
  "rejectionReason": "سبب الرفض (required when status = 5)"
}
```

**Admin:** can set **any status 0–5** with no transition rules.  
**Company/Customer apps** have strict transitions — admin dashboard bypasses them.

### Edit booking fields

```http
PATCH /api/Bookings/UpdateBooking/{id}
```

```json
{
  "userId": 11,
  "companyId": 5,
  "workerId": 10,
  "workTypeId": 9,
  "bookingDate": "2026-06-01T00:00:00Z",
  "startDate": "08:00",
  "endDate": "17:00",
  "address": "...",
  "userLocationId": 6
}
```

Only **Admin** can change `userId`.

### Delete (hard delete)

```http
DELETE /api/Bookings/DeleteBooking/{id}
```

### Filters (client-side)

- By status
- By company
- By date range
- Search by customer name

### Pricing & wallet (display)

- List column **الإجمالي** = `totalPrice`
- Detail: price breakdown card (service + platform fee + total)
- Wallet badges: محجوز من المحفظة / تم الخصم / تم تأكيد الوصول (read-only for admin)
- See **`ADMIN_DASHBOARD_LATEST_UPDATE_PROMPT.md`** for reserve/capture rules

---

## 7. Module: Workers

### List all (Admin only)

```http
GET /api/Workers/GetWorkers?page=1&pageSize=20
```

**Response item (`WorkerDTO`):**

```typescript
interface Worker {
  id: number;
  companyId: number;
  companyName?: string;
  fullName: string;
  nationalityId: number;
  nationalityName?: string;
  age: number;
  experienceYears: number;
  isAvailable: boolean;
  profileImage?: string;
  healthCertificate?: string;
  healthCertificateURL?: string;
  healthCertificateExpiryDate?: string;
  languagesIds?: string;       // comma-separated e.g. "1,2,3"
  isActive: boolean;
  createdAt: string;
}
```

### By company

```http
GET /api/Workers/Company/{companyId}?page=1&pageSize=20
```

### Create

```http
POST /api/Workers/CreateWorker
```

```json
{
  "companyId": 5,
  "fullName": "...",
  "nationalityId": 1,
  "age": 25,
  "experienceYears": 3,
  "isAvailable": true,
  "healthCertificate": "...",
  "healthCertificateExpiryDate": "2027-01-01",
  "languagesIds": "1,2"
}
```

### Update

```http
PATCH /api/Workers/UpdateWorker/{id}
```

### Toggles

```http
PATCH /api/Workers/UpdateWorkerIsActive/{id}
PATCH /api/Workers/UpdateWorkerIsAvailable/{id}
```

Both return `{ message, isActive/isAvailable }`.

### Health certificate upload

```http
POST /api/Workers/UploadHealthCertificate/{id}
PUT  /api/Workers/UpdateHealthCertificate/{id}
```

Multipart `file` — JPG, JPEG, PNG, PDF — max 10MB.

### Delete (hard delete)

```http
DELETE /api/Workers/DeleteWorker/{id}
```

---

## 8. Module: Work Types

### List all

```http
GET /api/WorkTypes/GetAllWorkTypes?page=1&pageSize=20
```

**Response item (`WorkTypeDTO`):**

```typescript
interface WorkType {
  id: number;
  name: string;
  companyId: number;
  companyName?: string;
  startTime: string;
  endTime: string;
  isOvernight: boolean;
  price: number;
  monthlyPrice?: number;
  isMonthly: boolean;   // derived: monthlyPrice != null
  isActive: boolean;
  createdAt: string;
}
```

### By company

```http
GET /api/WorkTypes/GetWorkTypesByCompany/{companyId}?page=1&pageSize=20
```

### Create

```http
POST /api/WorkTypes/CreateWorkType
```

**Daily shift:**

```json
{
  "name": "صباحية",
  "companyId": 5,
  "startTime": "08:00",
  "endTime": "17:00",
  "isOvernight": false,
  "isMonthly": false,
  "price": 150
}
```

**Monthly contract:**

```json
{
  "name": "عقد شهري",
  "companyId": 5,
  "isMonthly": true,
  "price": 2000
}
```

When `isMonthly: true` → API sets `monthlyPrice = price`, `price = 0`, times = `"00:00"`.

### Update / Delete

```http
PATCH /api/WorkTypes/UpdateWorkType/{id}
DELETE /api/WorkTypes/DeleteWorkType/{id}
```

### Assign work type to worker

```http
POST /api/WorkTypes/AssignWorkTypeToWorker
{ "workerId": 10, "workTypeId": 9 }
```

```http
GET /api/WorkTypes/GetWorkerWorkTypes/{workerId}
DELETE /api/WorkTypes/RemoveWorkTypeFromWorker?workerId=10&workTypeId=9
```

---

## 9. Module: Reviews

### List all (Admin only)

```http
GET /api/Reviews/GetReviews?page=1&pageSize=20
```

**Response item (`ReviewDTO`):**

```typescript
interface Review {
  id: number;
  bookingId: number;
  userId: number;
  userName?: string;
  workerId: number;
  workerName?: string;
  rating: number;       // 1–5
  comment?: string;
  createdAt: string;
}
```

### Update / Delete

```http
PATCH /api/Reviews/UpdateReview/{id}
{ "rating": 4, "comment": "..." }

DELETE /api/Reviews/DeleteReview/{id}
```

### By worker / booking (support views)

```http
GET /api/Reviews/Worker/{workerId}?page=1&pageSize=20
GET /api/Reviews/Booking/{bookingId}?page=1&pageSize=20
```

---

## 10. Module: Favorites

### List all (Admin only)

```http
GET /api/Favorites/GetFavorites?page=1&pageSize=20
```

**Response item (`FavoriteDTO`):**

```typescript
interface Favorite {
  id: number;
  userId: number;
  userName?: string;
  workerId: number;
  workerName?: string;
  workerProfileImage?: string;
  companyId: number;
  companyName?: string;
  createdAt: string;
}
```

### Delete

```http
DELETE /api/Favorites/DeleteFavorite/{id}
DELETE /api/Favorites/DeleteFavoriteByUserAndWorker/{userId}/{workerId}
```

Read-only analytics view — no create from admin.

---

## 11. Module: Reference Data

### Cities (paginated, CRUD Admin only)

```http
GET  /api/Cities/GetAllCities?page=1&pageSize=50     [Anonymous]
GET  /api/Cities/GetCityById/{id}                    [Anonymous]
POST /api/Cities/CreateCity                          [Admin]
PATCH /api/Cities/UpdateCity/{id}                    [Admin]
DELETE /api/Cities/DeleteCity/{id}                   [Admin — soft delete]
```

**CityDTO:** `{ id, name, code?, isActive }`  
**Create:** `{ name, code?, isActive: true }`

Use cities in dropdowns across Users, Companies, Workers forms.

### Nationalities (full list, partial CRUD)

```http
GET  /api/Nationalities/GetNationalities              [Anonymous — array]
POST /api/Nationalities/CreateNationality             [Admin]
PATCH /api/Nationalities/UpdateNationality/{id}       [Admin]
```

No delete endpoint — deactivate via PATCH `{ isActive: false }` if supported.

### Languages (full list, partial CRUD)

```http
GET  /api/Languages/GetAllLanguages                   [Anonymous — array]
POST /api/Languages/CreateLanguage                      [Admin]
PATCH /api/Languages/UpdateLanguage/{id}              [Admin]
```

### Cleaning Services (paginated CRUD)

```http
GET  /api/CleaningServices/GetCleaningServices?page=1&pageSize=20
POST /api/CleaningServices/CreateCleaningService
PATCH /api/CleaningServices/UpdateCleaningService/{id}
DELETE /api/CleaningServices/DeleteCleaningService/{id}
```

**DTO:** `{ id, name, description? }`

### User Types (read-only)

```http
GET /api/UserTypes
```

Returns `[{ id, name, description? }]` — use for filters/labels.

---

## 12. Module: System / Email Test

```http
POST /api/AppUsers/TestEmail
Authorization: Bearer {token}
```

```json
{
  "toEmail": "you@gmail.com",
  "template": "welcome"
}
```

| `template` | Preview |
|------------|---------|
| `password-reset-otp` | Customer OTP (rose) |
| `company-password-reset-otp` | Company OTP (teal) |
| `welcome` | Welcome email |
| `password-changed` | Password changed |
| `auto-reply` | Auto reply |
| *(omit)* | Plain SMTP test |

Response: `{ success: boolean, message: string }`

Build a simple form under `/system/email-test` for SMTP diagnostics.

---

## 13. Project structure (recommended)

```
src/
├── api/
│   ├── client.ts
│   ├── auth.api.ts
│   ├── users.api.ts
│   ├── companies.api.ts
│   ├── bookings.api.ts
│   ├── workers.api.ts
│   ├── workTypes.api.ts
│   ├── reviews.api.ts
│   ├── favorites.api.ts
│   └── reference.api.ts
├── types/
│   ├── api.types.ts          # PagedResult, entities
│   └── booking-status.ts
├── hooks/
│   ├── useAuth.ts
│   └── usePagination.ts
├── components/
│   ├── layout/
│   │   ├── AdminLayout.tsx
│   │   ├── Sidebar.tsx
│   │   └── TopBar.tsx
│   ├── ui/                   # buttons, badges, dialogs
│   ├── DataTable.tsx
│   ├── Pagination.tsx
│   ├── StatusBadge.tsx
│   ├── FilePreview.tsx
│   └── ConfirmDialog.tsx
├── pages/
│   ├── LoginPage.tsx
│   ├── DashboardPage.tsx
│   ├── users/
│   ├── companies/
│   │   ├── CompaniesListPage.tsx
│   │   ├── PendingCompaniesPage.tsx
│   │   └── CompanyDetailPage.tsx
│   ├── bookings/
│   ├── workers/
│   ├── work-types/
│   ├── reviews/
│   ├── favorites/
│   ├── reference/
│   └── settings/
│       ├── PlatformFeePage.tsx
│       └── WalletSettingsPage.tsx
│   └── wallet/
│       └── WalletTopUpsPage.tsx
├── routes/
│   └── AppRoutes.tsx         # ProtectedRoute wrapper
├── store/ or context/
│   └── AuthContext.tsx
└── utils/
    ├── formatDate.ts
    └── buildFileUrl.ts
```

---

## 14. UI/UX requirements

- **Language:** Arabic primary (RTL). Optional English toggle later.
- **Theme:** Professional admin — suggest Bareq rose accent `#E11D48` or neutral slate with rose highlights
- **Tables:** Sortable columns where sensible, row actions (view, edit, delete, toggle)
- **Confirm dialogs** before delete / reject / deactivate
- **Toast notifications** for success/error (display API Arabic messages)
- **Loading skeletons** on all data fetches (TanStack Query `isLoading`)
- **Empty states** with Arabic copy when `items.length === 0`
- **Forms:** react-hook-form + zod validation mirroring API rules
- **Date/time:** display in local Libya timezone; API uses UTC ISO strings
- **Maps (optional):** show booking `lat`/`lng` on detail if present

---

## 15. Environment variables

```env
VITE_API_URL=http://102.203.200.55:5545
```

For local dev, API CORS allows `localhost:5173`, `localhost:3000`.

---

## 16. Known API gaps (handle in UI)

1. **`CompanyDTO` has no `isActive`** — refresh after toggle or show verified badge only
2. **`UpdateCompanyisVerified` toggles BOTH verified and active** — document in approve button tooltip
3. **`GetCompanyById` hides unverified companies** — admin must use `GetAllCompanies`
4. **`AppUserDTO` has no `cityId`** — not shown in list
5. **No Nationality/Language delete** — use update to deactivate
6. **Wallet payments** — see `ADMIN_DASHBOARD_WALLET_PROMPT.md` (settings, cash top-up approval, electronic complete). Legacy `PaymentsController` CRUD remains disabled; wallet creates `Payment` rows server-side on booking.
7. **Toggle endpoints** (`UpdateCompanyIsActive`, etc.) have no request body — PATCH with empty body

---

## 17. Security rules

- Never log JWT, passwords, or OTP codes
- Clear token on logout
- Protect all routes except `/login` and `/setup`
- Validate Admin role client-side AND rely on API 403
- Sanitize file preview URLs (only allow `/Uploads/` paths from API)

---

## 18. Testing checklist

- [ ] Login with `userType: "Admin"` → dashboard
- [ ] Non-admin login rejected
- [ ] 401 redirects to login
- [ ] All list pages parse `PagedResult` correctly
- [ ] Pagination next/prev works
- [ ] Pending companies queue shows `isVerified: false`
- [ ] Approve company → `UpdateCompanyisVerified`
- [ ] Commercial register PDF/image preview
- [ ] Booking status change (admin override all statuses)
- [ ] Reject booking requires rejection reason
- [ ] Worker health certificate upload
- [ ] Work type monthly vs daily create forms
- [ ] Cities CRUD
- [ ] Test email sends successfully
- [ ] Soft delete user removes from list
- [ ] RTL layout correct on all pages
- [ ] Wallet settings enable + fee % (see `ADMIN_DASHBOARD_WALLET_PROMPT.md`)
- [ ] Cash top-up approve / reject queue

---

## 19. Related feature prompts

| Feature | File |
|---------|------|
| **Latest deltas (read first if updating)** | `ADMIN_DASHBOARD_LATEST_UPDATE_PROMPT.md` |
| Platform fee | `ADMIN_DASHBOARD_PLATFORM_FEE_PROMPT.md` |
| Wallet payment | `ADMIN_DASHBOARD_WALLET_PROMPT.md` |
| Notifications | `ADMIN_DASHBOARD_NOTIFICATIONS_PROMPT.md` |
| Customer reports | `ADMIN_REPORTS_IMPLEMENTATION_PROMPT.md` |
| Reference data CRUD | `ADMIN_REFERENCE_DATA_CRUD_PROMPT.md` |

---

## 20. Do NOT

- Parse list responses as root arrays
- Use `GetCompanyById` for admin pending review
- Assume `isVerified` approve only sets verified (it toggles active too)
- Build a generic payments CRUD module (use wallet admin prompts instead)
- Skip `userType: "Admin"` on login
- Hardcode entity IDs — always load from API

---

## PROMPT END
