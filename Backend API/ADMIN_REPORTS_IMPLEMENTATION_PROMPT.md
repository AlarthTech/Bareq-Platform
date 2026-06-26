# Admin Dashboard — Reports Module (Copy-Paste Prompt)

Copy everything below the line into your **Bareq Admin Dashboard** web front-end agent.

---

## PROMPT START

Implement the **Reports (البلاغات)** module in the Bareq Admin Dashboard.

**Base URL:** `http://102.203.200.55:5545`  
**Auth:** Admin JWT — `Authorization: Bearer {token}`  
Login: `POST /api/AppUsers/Login` with `"userType": "Admin"`

Only **Admin** can list all reports and update status. Company owners **cannot** see reports against them.

---

## Business rules

- Customers submit reports against a **worker** or a **company**
- Admin sees **all** reports with reporter name, target name, status, and internal notes
- Admin can change status and add **adminNotes** (internal — customers never see this)
- Admin can delete any report
- List is **paginated** (`PagedResult`)

---

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/Reports/GetReports?page=1&pageSize=20` | All reports (Admin) |
| GET | `/api/Reports/GetReportById/{id}` | Single report |
| PATCH | `/api/Reports/UpdateReportStatus/{id}` | Update status + notes |
| DELETE | `/api/Reports/DeleteReport/{id}` | Delete report |

---

## Report DTO

```typescript
interface Report {
  id: number;
  userId: number;
  userName?: string;           // reporter (customer)
  targetType: 1 | 2;          // 1 = Worker, 2 = Company
  targetTypeName: string;       // "عاملة" | "شركة"
  workerId?: number;
  workerName?: string;
  companyId?: number;
  companyName?: string;
  description: string;
  status: 0 | 1 | 2 | 3;
  statusName: string;
  adminNotes?: string;          // Admin only — visible in GetReports
  createdAt: string;
  updatedAt?: string;
}
```

### Status enum

| Value | API key | Arabic label | Badge color |
|-------|---------|--------------|-------------|
| 0 | Pending | قيد الانتظار | yellow |
| 1 | UnderReview | قيد المراجعة | blue |
| 2 | Resolved | تم الحل | green |
| 3 | Dismissed | مرفوض | gray |

### Target type

| Value | Meaning |
|-------|---------|
| 1 | Worker (عاملة) |
| 2 | Company (شركة) |

---

## List all reports

```http
GET /api/Reports/GetReports?page=1&pageSize=20
Authorization: Bearer {adminToken}
```

**Response:**

```json
{
  "items": [
    {
      "id": 1,
      "userId": 11,
      "userName": "محمد بن حامد",
      "targetType": 1,
      "targetTypeName": "عاملة",
      "workerId": 10,
      "workerName": "سعاد",
      "companyId": null,
      "companyName": null,
      "description": "العاملة تأخرت عن الموعد المتفق عليه",
      "status": 0,
      "statusName": "قيد الانتظار",
      "adminNotes": null,
      "createdAt": "2026-05-31T11:00:00Z",
      "updatedAt": null
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
GET /api/Reports/GetReportById/1
Authorization: Bearer {adminToken}
```

Returns single `Report` object. **403** if not Admin and not owner (Admin always allowed).

---

## Update status (Admin)

```http
PATCH /api/Reports/UpdateReportStatus/1
Authorization: Bearer {adminToken}
Content-Type: application/json
```

```json
{
  "status": 2,
  "adminNotes": "تم التواصل مع الشركة واتخاذ الإجراء اللازم"
}
```

**Success (200):** returns updated `Report` with `adminNotes`.

---

## Delete report

```http
DELETE /api/Reports/DeleteReport/1
Authorization: Bearer {adminToken}
```

**Success: 204**

---

## API service (TypeScript)

```typescript
// api/reports.api.ts
import { api } from './client';
import type { PagedResult, Report } from '../types';

export type ReportStatus = 0 | 1 | 2 | 3;

export const reportsApi = {
  list: (page = 1, pageSize = 20) =>
    api.get<PagedResult<Report>>('/api/Reports/GetReports', {
      params: { page, pageSize },
    }),

  getById: (id: number) =>
    api.get<Report>(`/api/Reports/GetReportById/${id}`),

  updateStatus: (id: number, data: { status: ReportStatus; adminNotes?: string }) =>
    api.patch<Report>(`/api/Reports/UpdateReportStatus/${id}`, data),

  remove: (id: number) =>
    api.delete(`/api/Reports/DeleteReport/${id}`),
};
```

---

## TanStack Query hooks

```typescript
export function useReports(page: number, pageSize = 20) {
  return useQuery({
    queryKey: ['reports', page, pageSize],
    queryFn: () => reportsApi.list(page, pageSize).then(r => r.data),
  });
}

export function useUpdateReportStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: { id: number; status: ReportStatus; adminNotes?: string }) =>
      reportsApi.updateStatus(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['reports'] }),
  });
}
```

---

## UI — Reports list page

**Route:** `/reports`

### Table columns (RTL Arabic)

| Column | Field |
|--------|-------|
| # | `id` |
| المُبلِّغ | `userName` |
| النوع | `targetTypeName` |
| الهدف | `workerName` or `companyName` |
| الوصف | `description` (truncate 80 chars) |
| الحالة | `statusName` badge |
| التاريخ | `createdAt` |
| إجراءات | View · Update status · Delete |

### Filters (client-side)

- By status (dropdown: الكل / قيد الانتظار / قيد المراجعة / تم الحل / مرفوض)
- By target type (عاملة / شركة)
- Search in description or reporter name

### Sidebar

Add menu item **"البلاغات"** with badge showing count of `status === 0` (pending).

---

## UI — Report detail drawer / page

**Route:** `/reports/:id`

Show:

- Reporter: `userName` (link to user if users module exists)
- Target: worker or company name + ID
- Full `description`
- Status badge
- `createdAt` / `updatedAt`
- **Admin notes** section (editable)

**Actions:**

1. **Change status** — dropdown + optional notes textarea → `UpdateReportStatus`
2. **Delete** — confirm dialog → `DeleteReport`

### Status update modal

| Field | Input |
|-------|-------|
| الحالة | select: 0, 1, 2, 3 |
| ملاحظات الإدارة | textarea (optional, max 2000) |

Button: **حفظ**

---

## Dashboard widget (optional)

On `/dashboard`, add card:

- **بلاغات قيد الانتظار** — count from `GetReports?page=1&pageSize=1` filtered by pending, or fetch and count client-side
- Link to `/reports?status=0`

---

## Error handling

| Code | Action |
|------|--------|
| 401 | Redirect to login |
| 403 | Toast "لا تملك صلاحية" |
| 404 | "البلاغ غير موجود" |
| 400 | Show API Arabic message |

---

## Testing checklist

- [ ] Admin login → `/reports` loads paginated list
- [ ] Pending reports badge in sidebar
- [ ] Filter by status works
- [ ] View report detail shows reporter + target + description
- [ ] Update status to Resolved with admin notes
- [ ] Delete report removes from list
- [ ] Pagination next/prev works
- [ ] Non-admin token returns 403 on GetReports

---

## Do NOT

- Expose reports to Company role
- Parse list as root array (use `PagedResult`)
- Show adminNotes to customer-facing UI

---

## PROMPT END
