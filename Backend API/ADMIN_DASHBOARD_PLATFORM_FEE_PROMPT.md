# Admin Dashboard — Platform Fee Management (Copy-Paste Prompt)

Copy everything below the line into Cursor / your **Bareq Admin Dashboard** web front-end agent.

---

## PROMPT START

Implement **Platform Fee (Commission) Management** in the **Bareq Admin Dashboard** and update **Bookings** screens to show stored pricing breakdown.

**API Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Backend reference:** `PLATFORM_FEE_IMPLEMENTATION.md`

The platform fee is a **fixed amount (LYD)** added to every new booking. Admins set the fee; customers see it before confirming a booking. **Historical bookings keep their original fee** — only display stored values, never recalculate.

---

## Business rules

| Rule | Detail |
|------|--------|
| Who can edit | **Admin only** |
| Fee type | Fixed amount per booking (not percentage) |
| Minimum | `0` (free platform fee allowed) |
| Active setting | Only one active fee in DB; API handles this |
| Booking prices | Read `servicePrice`, `platformFeeAmount`, `totalPrice` from API — **do not compute** on admin UI |
| After fee change | New bookings use new fee; old bookings unchanged |

---

## 1. Navigation & placement

Add a settings entry under **الإعدادات** or **المالية**:

| Arabic label | English | Route |
|--------------|---------|-------|
| رسوم المنصة | Platform Fee | `/settings/platform-fee` |

Optional sidebar icon: `payments` / `account_balance`.

Show current fee in sidebar subtitle when loaded: **"5 د.ل"**.

---

## 2. Platform Fee settings page

### Load on mount

```http
GET /api/v1/admin/platform-fee
Authorization: Bearer {adminToken}
```

**Response (200):**

```json
{
  "fixedPlatformFeeAmount": 5
}
```

### Save

```http
PUT /api/v1/admin/platform-fee
Authorization: Bearer {adminToken}
Content-Type: application/json
```

```json
{
  "fixedPlatformFeeAmount": 5
}
```

**Success (200):**

```json
{
  "success": true,
  "fixedPlatformFeeAmount": 5
}
```

**Errors:**

| Status | Handling |
|--------|----------|
| 400 | Validation — fee must be ≥ 0 |
| 401 | Redirect to login |
| 403 | "غير مصرح — للمسؤولين فقط" |

---

## 3. Settings page UI (RTL Arabic)

```
┌─────────────────────────────────────────────────┐
│  رسوم المنصة                                    │
├─────────────────────────────────────────────────┤
│  المبلغ الثابت المضاف على كل حجز جديد          │
│                                                 │
│  [  5.00  ]  د.ل                               │
│                                                 │
│  ℹ️ يُطبَّق على الحجوزات الجديدة فقط.          │
│     الحجوزات السابقة تحتفظ بالرسوم المحفوظة.    │
│                                                 │
│              [ حفظ التغييرات ]                  │
└─────────────────────────────────────────────────┘
```

### Form behavior

| Element | Behavior |
|---------|----------|
| Input | `type="number"`, `min="0"`, `step="0.01"` |
| Currency suffix | **د.ل** (Libyan Dinar) |
| Save button | Disabled while loading or if value unchanged |
| Loading | Skeleton on first fetch |
| Success | Toast: **"تم تحديث رسوم المنصة بنجاح"** |
| Error | Show API `message` or ModelState errors |

### Client validation (before submit)

```typescript
function validatePlatformFee(value: number): string | null {
  if (Number.isNaN(value)) return 'يرجى إدخال مبلغ صالح';
  if (value < 0) return 'لا يمكن أن تكون رسوم المنصة سالبة';
  return null;
}
```

### Confirm dialog (recommended)

When increasing fee significantly, optional confirm:

**"سيتم تطبيق الرسوم الجديدة على الحجوزات القادمة فقط. هل تريد المتابعة؟"**

---

## 4. TypeScript types

```typescript
interface PlatformFeeResponse {
  fixedPlatformFeeAmount: number;
}

interface UpdatePlatformFeeRequest {
  fixedPlatformFeeAmount: number;
}

interface UpdatePlatformFeeResponse {
  success: boolean;
  fixedPlatformFeeAmount: number;
}
```

---

## 5. API service layer

```typescript
// src/features/platform-fee/api/platformFee.api.ts
import { apiClient } from '@/lib/apiClient';

export async function getPlatformFee(): Promise<PlatformFeeResponse> {
  const { data } = await apiClient.get<PlatformFeeResponse>('/api/v1/admin/platform-fee');
  return data;
}

export async function updatePlatformFee(
  payload: UpdatePlatformFeeRequest
): Promise<UpdatePlatformFeeResponse> {
  const { data } = await apiClient.put<UpdatePlatformFeeResponse>(
    '/api/v1/admin/platform-fee',
    payload
  );
  return data;
}
```

Use **TanStack Query**:

```typescript
// usePlatformFee.ts
export function usePlatformFee() {
  return useQuery({ queryKey: ['platform-fee'], queryFn: getPlatformFee });
}

export function useUpdatePlatformFee() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: updatePlatformFee,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['platform-fee'] });
    },
  });
}
```

---

## 6. Update Bookings module — pricing columns

All booking endpoints now return stored prices. Update `Booking` interface everywhere in the admin app.

### Extended `BookingDTO`

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
  startDate: string;
  endDate: string;
  address?: string;
  userLocationId?: number;
  locationName?: string;
  lat?: number;
  lng?: number;
  status: number;
  rejectionReason?: string;
  servicePrice: number;
  platformFeeAmount: number;
  totalPrice: number;
  isMonthlyPricing: boolean;
  createdAt: string;
}
```

**List endpoint:** `GET /api/Bookings/GetBookings?page=1&pageSize=20`  
**Detail:** `GET /api/Bookings/GetBookingById/{id}`

---

## 7. Bookings list — add price column

| Column (AR) | Field | Format |
|-------------|-------|--------|
| الإجمالي | `totalPrice` | `105.00 د.ل` |
| رسوم المنصة | `platformFeeAmount` | `5.00 د.ل` (optional column, hide on mobile) |
| سعر الخدمة | `servicePrice` | `100.00 د.ل` (optional) |

Default visible: **الإجمالي** only; expand row or detail for full breakdown.

Sort/filter: allow sort by `totalPrice` client-side if needed.

---

## 8. Booking detail — pricing card

Add a **"تفاصيل السعر"** card (read-only):

```
┌─────────────────────────────────────┐
│  تفاصيل السعر                       │
├─────────────────────────────────────┤
│  سعر الخدمة          100.00 د.ل     │
│  رسوم المنصة           5.00 د.ل     │
│  ─────────────────────────────      │
│  الإجمالي            105.00 د.ل     │
│                                     │
│  نوع التسعير: شهري / يومي            │
└─────────────────────────────────────┘
```

```typescript
function PricingBreakdown({ booking }: { booking: Booking }) {
  const pricingType = booking.isMonthlyPricing ? 'تسعير شهري' : 'تسعير يومي';
  return (
    <Card title="تفاصيل السعر">
      <Row label="سعر الخدمة" value={formatLyd(booking.servicePrice)} />
      <Row label="رسوم المنصة" value={formatLyd(booking.platformFeeAmount)} />
      <Divider />
      <Row label="الإجمالي" value={formatLyd(booking.totalPrice)} bold />
      <Caption>{pricingType}</Caption>
    </Card>
  );
}
```

```typescript
function formatLyd(amount: number): string {
  return `${amount.toFixed(2)} د.ل`;
}
```

**Important:** If `servicePrice === 0 && platformFeeAmount === 0 && totalPrice === 0`, show badge:

**"حجز قديم — لم يُسجَّل تسعير"** (legacy booking before platform fee feature).

---

## 9. Dashboard stats (optional enhancement)

On main dashboard, add KPI cards fed from bookings list aggregation (client-side or future report API):

| KPI | Arabic | Calculation (from loaded bookings or dedicated report) |
|-----|--------|--------------------------------------------------------|
| Total platform fees | إجمالي رسوم المنصة | `sum(booking.platformFeeAmount)` |
| Total revenue | إجمالي الإيرادات | `sum(booking.totalPrice)` |
| Service revenue | إيرادات الخدمات | `sum(booking.servicePrice)` |

Filter by date range / company when filters exist.

> Full financial reporting API is not required for v1 — aggregate from `GetBookings` pages or add later.

---

## 10. Suggested file structure

```
src/features/platform-fee/
├── api/platformFee.api.ts
├── hooks/usePlatformFee.ts
├── pages/PlatformFeeSettingsPage.tsx
└── components/PlatformFeeForm.tsx

src/features/bookings/
├── types/booking.ts          # add price fields
├── components/BookingPricingCard.tsx
└── components/BookingsTable.tsx  # add totalPrice column
```

---

## 11. Security

- Attach `Authorization: Bearer {token}` from admin login (`userType: "Admin"`).
- Never call platform-fee endpoints from customer/company apps.
- Do not expose an input on booking create/edit to change `platformFeeAmount` — admin only sets global fee; bookings store snapshot at creation.

---

## 12. Login reminder

```http
POST /api/AppUsers/Login
```

```json
{
  "username": "admin@example.com",
  "password": "...",
  "userType": "Admin"
}
```

---

## 13. Acceptance checklist

- [ ] Settings page loads current platform fee on mount
- [ ] Admin can save fee `0` successfully
- [ ] Admin can save positive fee (e.g. `5`)
- [ ] Negative values blocked client-side and show API error if bypassed
- [ ] Success toast after save; displayed value updates
- [ ] Non-admin gets 403 on platform-fee routes
- [ ] Bookings list shows `totalPrice` column
- [ ] Booking detail shows service / platform fee / total breakdown
- [ ] Legacy bookings with `0` prices show explanatory note
- [ ] `isMonthlyPricing` shown as يومي / شهري on detail
- [ ] RTL layout and Arabic labels correct
- [ ] No client-side recalculation of booking prices

---

## 14. Do NOT

- Compute `totalPrice = servicePrice + platformFee` in admin UI for display — use API values
- Allow editing per-booking platform fee in admin (only global setting)
- Use percentage-based fee UI (backend is fixed amount only)
- Call `POST /api/v1/bookings/price-preview` from admin app (customer-only)
- Change booking prices when admin updates global platform fee

## PROMPT END
