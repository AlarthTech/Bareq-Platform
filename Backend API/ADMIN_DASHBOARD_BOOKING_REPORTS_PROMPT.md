# Admin Dashboard — Booking Reports Module (Copy-Paste Prompt)

Copy everything below the line into your **Bareq Admin Dashboard** web front-end agent.

---

## PROMPT START

Implement the **Booking Reports (بلاغات الحجوزات)** module in the Bareq Admin Dashboard.

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Auth:** Admin JWT — `Authorization: Bearer {token}`  
Login: `POST /api/AppUsers/Login` with `"userType": "Admin"`

This module is **separate** from customer worker/company reports (`/api/Reports/*`).  
Booking reports are complaints tied to a **specific booking** (delay, unfair rejection, company behavior, etc.).

**Admin** sees all reports. **Company owners** can list, view, and resolve reports for their own company's bookings via the **Company app** (`FLUTTER_COMPANY_BOOKING_REPORTS_PROMPT.md`) using the same API with `userType: Company` JWT.

---

## Business rules

1. Customer creates report on their own booking (status: Pending, Approved, OnTheWay, or Rejected).
2. Admin sees **all** booking reports with customer, company, worker, and booking context.
3. Admin updates status to **InReview**, **Resolved**, or **Rejected** — cannot set back to **Open** via API.
4. **AdminResolutionNotes** required when status is **Resolved** or **Rejected**.
5. Resolving/rejecting a report **does not** change the booking status.
6. Customer is notified when admin resolves or rejects (`notificationType: 22`).
7. No delete endpoint — reports are permanent audit records.

---

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/BookingReports` | All reports with filters + pagination (Admin) |
| GET | `/api/BookingReports/{id}` | Report detail (Admin) |
| PATCH | `/api/BookingReports/{id}/Status` | Update status + resolution notes (Admin) |

> Customer endpoints (`POST`, `MyReports`, `Booking/{id}`) are **not** used in admin dashboard.

---

## TypeScript types

```typescript
// types/booking-report.ts

export type BookingReportStatus = 0 | 1 | 2 | 3;

export interface BookingReport {
  id: number;
  bookingId: number;
  customerId: number;
  customerName: string;
  companyId: number;
  companyName: string;
  workerId?: number;
  workerName?: string;
  reason: string;
  description?: string;
  status: BookingReportStatus;
  statusName: string;
  adminResolutionNotes?: string;
  resolvedByAdminId?: number;
  resolvedByAdminName?: string;
  resolvedAt?: string;
  createdAt: string;
  updatedAt?: string;
  bookingStatus: number;
  bookingStatusName: string;
}

export interface BookingReportFilters {
  status?: BookingReportStatus;
  bookingId?: number;
  customerId?: number;
  companyId?: number;
  workerId?: number;
  fromDate?: string;   // ISO date YYYY-MM-DD
  toDate?: string;     // ISO date YYYY-MM-DD
  page?: number;
  pageSize?: number;
}

export interface UpdateBookingReportStatusPayload {
  status: 1 | 2 | 3;   // InReview | Resolved | Rejected only
  adminResolutionNotes?: string;
}

export interface PagedResult<T> {
  items: T[];
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}
```

### Report status enum

| Value | Key | Arabic (`statusName`) | Badge |
|-------|-----|----------------------|-------|
| 0 | Open | مفتوح | orange |
| 1 | InReview | قيد المراجعة | blue |
| 2 | Resolved | تم الحل | green |
| 3 | Rejected | مرفوض | red |

### Booking status (context column)

| Value | `bookingStatusName` |
|-------|---------------------|
| 0 | قيد الانتظار |
| 1 | مؤكد |
| 2 | في الطريق |
| 3 | مكتمل |
| 4 | ملغي |
| 5 | مرفوض |

Use `bookingStatusName` from API — do not hardcode if API returns it.

---

## List all booking reports

```http
GET /api/BookingReports?status=0&bookingId=80&page=1&pageSize=20
Authorization: Bearer {adminToken}
```

### Query parameters (all optional)

| Param | Type | Description |
|-------|------|-------------|
| `status` | int | 0 Open · 1 InReview · 2 Resolved · 3 Rejected |
| `bookingId` | int | Filter by booking |
| `customerId` | int | Filter by customer |
| `companyId` | int | Filter by company |
| `workerId` | int | Filter by worker |
| `fromDate` | date | Created on or after (UTC date) |
| `toDate` | date | Created before end of day |
| `page` | int | Default 1 |
| `pageSize` | int | Default 20, max 50 |

**Response:** `PagedResult<BookingReport>`

```json
{
  "items": [
    {
      "id": 1,
      "bookingId": 80,
      "customerId": 23,
      "customerName": "Mohamed benhamed",
      "companyId": 1013,
      "companyName": "البريق الامع",
      "workerId": 13,
      "workerName": "عبير الاسمر",
      "reason": "رفض غير مبرر",
      "description": "سبب الرفض غير واضح",
      "status": 0,
      "statusName": "مفتوح",
      "adminResolutionNotes": null,
      "resolvedByAdminId": null,
      "resolvedByAdminName": null,
      "resolvedAt": null,
      "createdAt": "2026-06-06T18:17:27.1780059",
      "updatedAt": null,
      "bookingStatus": 5,
      "bookingStatusName": "مرفوض"
    }
  ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 1,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

---

## Report detail

```http
GET /api/BookingReports/1
Authorization: Bearer {adminToken}
```

**Success (200):** single `BookingReport`  
**404:** `{ "message": "البلاغ غير موجود." }`

---

## Update status (Admin)

```http
PATCH /api/BookingReports/1/Status
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Mark in review (notes optional):**

```json
{
  "status": 1
}
```

**Resolve (notes required):**

```json
{
  "status": 2,
  "adminResolutionNotes": "تم التواصل مع الشركة ومعالجة الشكوى"
}
```

**Reject report (notes required):**

```json
{
  "status": 3,
  "adminResolutionNotes": "البلاغ لا يستوفي شروط المتابعة"
}
```

| Field | Rules |
|-------|--------|
| `status` | Must be **1**, **2**, or **3** only (not 0) |
| `adminResolutionNotes` | **Required** when `status` is 2 or 3; max **1000** chars |

**Success (200):** updated `BookingReport` with `resolvedByAdminId`, `resolvedByAdminName`, `resolvedAt` when status is 2 or 3.

**Errors (400):** Arabic `message` or ModelState, e.g.:

- `"ملاحظات الإدارة مطلوبة عند حل البلاغ أو رفضه."`
- `"حالة البلاغ يجب أن تكون قيد المراجعة أو تم الحل أو مرفوض."`
- `"البلاغ في هذه الحالة بالفعل."`

---

## API service (TypeScript)

```typescript
// api/booking-reports.api.ts
import { api } from './client';
import type {
  BookingReport,
  BookingReportFilters,
  PagedResult,
  UpdateBookingReportStatusPayload,
} from '../types/booking-report';

export const bookingReportsApi = {
  list: (filters: BookingReportFilters = {}) =>
    api.get<PagedResult<BookingReport>>('/api/BookingReports', {
      params: {
        page: filters.page ?? 1,
        pageSize: filters.pageSize ?? 20,
        ...(filters.status != null && { status: filters.status }),
        ...(filters.bookingId != null && { bookingId: filters.bookingId }),
        ...(filters.customerId != null && { customerId: filters.customerId }),
        ...(filters.companyId != null && { companyId: filters.companyId }),
        ...(filters.workerId != null && { workerId: filters.workerId }),
        ...(filters.fromDate && { fromDate: filters.fromDate }),
        ...(filters.toDate && { toDate: filters.toDate }),
      },
    }),

  getById: (id: number) =>
    api.get<BookingReport>(`/api/BookingReports/${id}`),

  updateStatus: (id: number, data: UpdateBookingReportStatusPayload) =>
    api.patch<BookingReport>(`/api/BookingReports/${id}/Status`, data),
};
```

---

## TanStack Query hooks

```typescript
// hooks/useBookingReports.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { bookingReportsApi } from '../api/booking-reports.api';
import type { BookingReportFilters, UpdateBookingReportStatusPayload } from '../types';

export function useBookingReports(filters: BookingReportFilters) {
  return useQuery({
    queryKey: ['booking-reports', filters],
    queryFn: () => bookingReportsApi.list(filters).then((r) => r.data),
  });
}

export function useBookingReport(id: number) {
  return useQuery({
    queryKey: ['booking-reports', id],
    queryFn: () => bookingReportsApi.getById(id).then((r) => r.data),
    enabled: id > 0,
  });
}

export function useUpdateBookingReportStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      ...data
    }: { id: number } & UpdateBookingReportStatusPayload) =>
      bookingReportsApi.updateStatus(id, data),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['booking-reports'] });
      qc.invalidateQueries({ queryKey: ['booking-reports', id] });
    },
  });
}
```

---

## Sidebar navigation

Add under **العمليات** (distinct from worker/company **البلاغات**):

```
العمليات
  ├── بلاغات العملاء        → /reports              (worker/company — existing)
  ├── بلاغات الحجوزات       → /booking-reports      (NEW)
  └── ...
```

Optional badge on **بلاغات الحجوزات**: count of `status === 0` (Open) from list API with `?status=0&page=1&pageSize=1` → use `totalCount`.

---

## UI — Booking reports list page

**Route:** `/booking-reports`

### Filter bar (server-side — pass as query params)

| Control | Param | Options |
|---------|-------|---------|
| الحالة | `status` | الكل · مفتوح (0) · قيد المراجعة (1) · تم الحل (2) · مرفوض (3) |
| رقم الحجز | `bookingId` | number input |
| العميل | `customerId` | number input (or customer search picker) |
| الشركة | `companyId` | number input (or company picker) |
| العاملة | `workerId` | number input |
| من تاريخ | `fromDate` | date picker |
| إلى تاريخ | `toDate` | date picker |

**Apply filters** → refetch with updated `queryKey`.  
**Reset** → clear params, `page=1`.

### Table columns (RTL Arabic)

| Column | Field |
|--------|-------|
| # | `id` |
| الحجز | `#bookingId` + link to `/bookings/{bookingId}` |
| حالة الحجز | `bookingStatusName` badge |
| العميل | `customerName` |
| الشركة | `companyName` |
| العاملة | `workerName` |
| السبب | `reason` (truncate 60) |
| حالة البلاغ | `statusName` badge |
| التاريخ | `createdAt` |
| إجراءات | عرض · تحديث الحالة |

### Row actions

- **عرض** → `/booking-reports/:id`
- **تحديث الحالة** → open status modal (same as detail page)

### Pagination

Use `page`, `totalPages`, `hasNextPage`, `hasPreviousPage` from API.

### Empty state

**"لا توجد بلاغات حجوزات"** when `items.length === 0`.

---

## UI — Report detail page

**Route:** `/booking-reports/:id`

### Sections

**1. Header**
- Report `#id` + `statusName` badge
- Created: `createdAt` · Updated: `updatedAt`

**2. Booking context card**
- Booking: `#bookingId` (link → `/bookings/{bookingId}`)
- Booking status: `bookingStatusName`
- Company: `companyName` (`companyId`)
- Worker: `workerName` (`workerId`)

**3. Customer**
- `customerName` (`customerId`)

**4. Report content**
- **السبب:** `reason`
- **التفاصيل:** `description` or "—"

**5. Resolution (if terminal)**
- Show when `status` is 2 or 3:
  - `adminResolutionNotes`
  - `resolvedByAdminName`
  - `resolvedAt`

### Actions panel

**Button: تحديث الحالة** → modal

---

## Status update modal

| Field | Input |
|-------|-------|
| الحالة الجديدة | select: **قيد المراجعة (1)** · **تم الحل (2)** · **مرفوض (3)** |
| ملاحظات الإدارة | textarea, max 1000 |

**Client validation:**

- If status is **2** or **3** → `adminResolutionNotes` required (trim, non-empty)
- Disable submit if same status as current (API returns 400 anyway)
- Character counter `{length}/1000`

**Suggested workflow buttons (quick actions on Open reports):**

| Button | Sets status |
|--------|-------------|
| بدء المراجعة | 1 |
| تم الحل | 2 (+ notes required) |
| رفض البلاغ | 3 (+ notes required) |

**On success:** toast **"تم تحديث حالة البلاغ"** · close modal · refresh detail.

**Note:** Customer receives push/in-app notification when status becomes 2 or 3.

---

## Booking detail integration (optional)

On admin **Booking detail** page (`/bookings/:id`):

- Add tab or section **"بلاغات الحجز"**
- Fetch: `GET /api/BookingReports?bookingId={id}&page=1&pageSize=20`
- List linked reports with status badges
- Link each row → `/booking-reports/{reportId}`

---

## Notifications integration

Admin receives notification on new booking report:

- `notificationType: 21` (BookingReportSubmitted)
- Message AR: **"تم تقديم بلاغ جديد على حجز."**
- `relatedEntityId` = **booking report id**

**Tap handler in notification dropdown:**

```typescript
if (notification.notificationType === 21 && notification.relatedEntityId) {
  navigate(`/booking-reports/${notification.relatedEntityId}`);
}
```

Do **not** confuse with:

- Type 4/5 → worker/company reports → `/reports/{id}`
- Types 10–16 → bookings → `/bookings/{relatedEntityId}`

---

## Dashboard widget (optional)

On `/dashboard`:

| Card | Data |
|------|------|
| بلاغات حجوزات مفتوحة | `GET /api/BookingReports?status=0&page=1&pageSize=1` → `totalCount` |
| Link | `/booking-reports?status=0` |

---

## Error handling

| Code | Action |
|------|--------|
| 401 | Redirect to `/login` |
| 403 | Toast "لا تملك صلاحية" |
| 404 | "البلاغ غير موجود" |
| 400 | Show `response.data.message` or first ModelState error (Arabic) |

Parse error body:

```typescript
function getApiErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data;
    if (typeof data?.message === 'string') return data.message;
    // ModelState: first error value
  }
  return 'حدث خطأ غير متوقع';
}
```

---

## Vite proxy (local dev)

If admin runs on `localhost:5173`, proxy `/api` to production:

```typescript
// vite.config.ts
server: {
  proxy: {
    '/api': { target: 'http://102.203.200.55:5545', changeOrigin: true },
    '/hubs': { target: 'http://102.203.200.55:5545', ws: true, changeOrigin: true },
  },
},
```

---

## Testing checklist

- [ ] Admin login → `/booking-reports` loads paginated list
- [ ] Filter by status, bookingId, companyId works (server-side)
- [ ] Date range filter works
- [ ] Open reports badge in sidebar (optional)
- [ ] View detail shows booking + customer + reason + description
- [ ] Update to InReview without notes → success
- [ ] Resolve without notes → blocked client + API 400
- [ ] Resolve with notes → success, shows resolvedBy + resolvedAt
- [ ] Reject with notes → success, customer notification sent (verify in notifications API)
- [ ] Link to booking detail from report works
- [ ] Notification type 21 opens correct report
- [ ] Pagination next/prev works
- [ ] Non-admin token returns 403 on list
- [ ] No delete button (endpoint does not exist)

---

## Do NOT

- Use `/api/Reports/*` for booking reports
- Allow status **0** (Open) in admin update modal
- Omit `adminResolutionNotes` when resolving/rejecting
- Delete reports (no API)
- Change booking status from this module
- Parse list response as root array (use `PagedResult.items`)
- Mix this module with worker/company reports in one table without labels

---

## Related docs

| Topic | File |
|-------|------|
| Worker/company reports | `ADMIN_REPORTS_IMPLEMENTATION_PROMPT.md` |
| Customer app (booking reports) | `FLUTTER_CUSTOMER_BOOKING_REPORTS_PROMPT.md` |
| Company app (resolve reports) | `FLUTTER_COMPANY_BOOKING_REPORTS_PROMPT.md` |
| Admin base | `ADMIN_DASHBOARD_IMPLEMENTATION_PROMPT.md` |
| Latest deltas | `ADMIN_DASHBOARD_LATEST_UPDATE_PROMPT.md` |
| Notifications | `ADMIN_DASHBOARD_NOTIFICATIONS_PROMPT.md` |

---

## PROMPT END
