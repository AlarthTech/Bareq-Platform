# Admin Dashboard — Wallet Payment Management (Copy-Paste Prompt)

Copy everything below the line into Cursor / your **Bareq Admin Dashboard** web front-end agent.

---

## PROMPT START

Implement **Wallet Payment Management** in the **Bareq Admin Dashboard**: wallet settings (enable/disable + fee %), cash top-up approval queue, electronic top-up completion, and booking payment visibility for wallet-paid bookings.

**API Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Backend reference:** `WALLET_PAYMENT_IMPLEMENTATION.md`

**Admin JWT required** on all endpoints below (`Authorization: Bearer {token}`).

---

## Business rules

| Rule | Detail |
|------|--------|
| Who can manage | **Admin only** |
| Wallet fee | **Percentage** of booking `totalPrice` (service + platform fee), not fixed LYD |
| Example | Booking total = 100 LYD, fee = 5% → customer pays **105 LYD** from wallet |
| Cash top-up | Customer requests → stays **Pending** until admin **approves** or **rejects** |
| Electronic top-up | Stays **Pending** until gateway confirms → admin or webhook calls **complete-electronic** |
| Wallet at booking | **Reserved** on create (`WalletReserve`); **captured** on customer arrival confirm or when booking **Completed** |
| Release | If **Canceled** / **Rejected** before capture → reserved amount returned to spendable balance |
| Refund | If **Canceled** / **Rejected** after capture → amount credited back (backend handles; show status in UI) |
| Default production | Wallet **disabled**, fee **0%** until admin enables |

---

## 1. Navigation & placement

Under **الإعدادات** / **المالية**:

| Arabic label | English | Route |
|--------------|---------|-------|
| إعدادات المحفظة | Wallet Settings | `/settings/wallet` |
| طلبات شحن المحفظة | Wallet Top-Ups | `/wallet/top-ups` |

Suggested sidebar structure:

```
المالية
  ├── رسوم المنصة        → /settings/platform-fee
  ├── إعدادات المحفظة    → /settings/wallet
  └── طلبات شحن المحفظة → /wallet/top-ups
```

Badge on **طلبات شحن المحفظة**: count of `status=Pending` + `paymentMethod=Cash`.

---

## 2. Wallet settings page (`/settings/wallet`)

### Load on mount

```http
GET /api/v1/admin/payment-settings/wallet
Authorization: Bearer {adminToken}
```

**Response (200):**

```json
{
  "isWalletPaymentEnabled": false,
  "walletPaymentFeePercentage": 0,
  "updatedAt": "2026-06-03T09:56:38Z",
  "updatedByAdminId": null
}
```

### Save

```http
PUT /api/v1/admin/payment-settings/wallet
Authorization: Bearer {adminToken}
Content-Type: application/json
```

```json
{
  "isWalletPaymentEnabled": true,
  "walletPaymentFeePercentage": 5
}
```

**Validation (mirror API):**

- `walletPaymentFeePercentage` must be **0–100**
- Show live preview: “على حجز بقيمة 100 د.ل، يُخصم من المحفظة: **105 د.ل**” when fee = 5%

**UI fields:**

| Field | Type | Arabic label |
|-------|------|----------------|
| `isWalletPaymentEnabled` | Toggle | تفعيل الدفع بالمحفظة |
| `walletPaymentFeePercentage` | Number (0–100, step 0.01) | نسبة رسوم الدفع بالمحفظة (%) |

**Footer:** show `updatedAt` + optional “آخر تحديث بواسطة المشرف #id”.

**Success toast:** `تم حفظ إعدادات المحفظة بنجاح`

**Errors:** display API `message` (400 validation).

---

## 3. Wallet top-ups queue (`/wallet/top-ups`)

### List (paginated)

```http
GET /api/v1/admin/wallet/top-ups?status=Pending&page=1&pageSize=20
Authorization: Bearer {adminToken}
```

**Query params:**

| Param | Values | Notes |
|-------|--------|-------|
| `status` | optional: `Pending`, `Completed`, `Rejected`, `Failed` | Omit = all |
| `page` | default 1 | |
| `pageSize` | default 20, max 50 | |

**Response (200):** standard `PagedResult`:

```json
{
  "items": [
    {
      "id": 12,
      "amount": 200,
      "paymentMethod": "Cash",
      "status": "Pending",
      "referenceNumber": null,
      "notes": "شحن نقدي من الفرع",
      "rejectionReason": null,
      "createdAt": "2026-06-03T10:00:00Z",
      "completedAt": null
    }
  ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 3,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

**Table columns:**

| Column | Source |
|--------|--------|
| # | `id` |
| العميل | Load via separate user lookup if needed — *top-up DTO has no name*; optional: extend UI with `GET /api/AppUsers/GetUserById/{customerId}` if you store `customerId` from detail — **note:** list DTO does not include `customerId`; add filter by fetching detail or ask backend to extend DTO later. For v1, show `id` + amount + method + dates. |
| المبلغ | `amount` + " د.ل" |
| طريقة الدفع | `Cash` → نقدي · `ElectronicPayment` → إلكتروني |
| الحالة | badge: Pending / Completed / Rejected |
| التاريخ | `createdAt` |
| إجراءات | Approve / Reject / Complete |

> **Backend note:** If you need `customerId` in the list, request a backend DTO extension. Until then, open a detail drawer that calls `GET /api/v1/wallet/top-up/{id}` is **customer-only**. Admin list item `id` is enough for approve/reject actions.

**Tabs / filters:** الكل · قيد الانتظار · مكتمل · مرفوض

---

## 4. Approve cash top-up

```http
POST /api/v1/admin/wallet/top-ups/{id}/approve
Authorization: Bearer {adminToken}
```

No body.

**Success (200):** updated `WalletTopUpDTO` with `status: "Completed"`.

**UI:**

- Confirm dialog: “تأكيد شحن المحفظة بمبلغ {amount} د.ل؟”
- Only show for `paymentMethod === "Cash"` && `status === "Pending"`
- Refresh list + decrement pending badge

**Errors (400):** show `message` (e.g. not pending, not cash).

---

## 5. Reject cash top-up

```http
POST /api/v1/admin/wallet/top-ups/{id}/reject
Authorization: Bearer {adminToken}
Content-Type: application/json
```

```json
{
  "rejectionReason": "لم يتم استلام المبلغ"
}
```

**Success (200):** `status: "Rejected"`, `rejectionReason` set.

**UI:** modal with required reason textarea (Arabic).

---

## 6. Complete electronic top-up

Use after payment gateway confirms payment (manual admin action until webhook exists).

```http
POST /api/v1/admin/wallet/top-ups/{id}/complete-electronic
Authorization: Bearer {adminToken}
Content-Type: application/json
```

```json
{
  "referenceNumber": "GW-20260603-ABC123"
}
```

**Success (200):** `status: "Completed"`.

**UI:**

- Only for `paymentMethod === "ElectronicPayment"` && `status === "Pending"`
- Optional reference number field (gateway transaction id)

---

## 7. Bookings module updates

### Booking list / detail

When displaying bookings, if payment exists with `paymentMethod === "Wallet"`:

| Field | Source |
|-------|--------|
| طريقة الدفع | المحفظة |
| إجمالي الحجز | `bookingTotalAmount` on payment (or `booking.totalPrice`) |
| رسوم المحفظة | `walletFeeAmount` |
| المبلغ المدفوع | `payment.amount` |
| حالة الاسترداد | `walletRefundStatus`: 0 = لا يوجد · 1 = تم الاسترداد |

Load payments if you add a payments read endpoint later; for now wallet payments are created server-side on booking — **optional:** `GET` booking detail and show wallet info from linked payment if API exposes it on booking DTO in future.

### Admin cancel / reject booking

No extra wallet API call — backend refunds automatically on status **Canceled** or **Rejected**.

Show toast after status change: “تم تحديث الحالة. إن كان الدفع بالمحفظة، يُعاد المبلغ تلقائياً.”

---

## 8. TypeScript types

```typescript
export interface WalletPaymentSettingsDTO {
  isWalletPaymentEnabled: boolean;
  walletPaymentFeePercentage: number;
  updatedAt: string;
  updatedByAdminId: number | null;
}

export interface UpdateWalletPaymentSettingsDTO {
  isWalletPaymentEnabled: boolean;
  walletPaymentFeePercentage: number;
}

export interface WalletTopUpDTO {
  id: number;
  amount: number;
  paymentMethod: 'Cash' | 'ElectronicPayment';
  status: 'Pending' | 'Completed' | 'Rejected' | 'Failed';
  referenceNumber: string | null;
  notes: string | null;
  rejectionReason: string | null;
  createdAt: string;
  completedAt: string | null;
}

export interface RejectWalletTopUpDTO {
  rejectionReason?: string;
}

export interface CompleteElectronicTopUpDTO {
  referenceNumber?: string;
}
```

---

## 9. React Query keys (suggested)

```typescript
['admin', 'wallet-settings']
['admin', 'wallet-top-ups', { status, page, pageSize }]
```

Invalidate `wallet-top-ups` after approve / reject / complete.

---

## 10. Error handling

| Scenario | HTTP | UI |
|----------|------|-----|
| Not admin | 403 | توجيه / رسالة صلاحية |
| Invalid fee % | 400 | رسالة التحقق |
| Approve non-pending | 400 | toast خطأ |
| Token expired | 401 | logout → login |

---

## 11. Testing checklist

- [ ] Load wallet settings — shows disabled + 0% by default
- [ ] Enable wallet + set 5% fee — saves successfully
- [ ] Top-ups list with `status=Pending` filter
- [ ] Approve cash top-up → status Completed
- [ ] Reject cash with reason → status Rejected, wallet not credited (verify via DB or customer app)
- [ ] Complete electronic top-up with reference number
- [ ] Pending badge count updates after actions
- [ ] RTL layout on settings + table pages

---

## 12. Do NOT

- Credit wallet on cash top-up without calling **approve** API
- Allow fee percentage &lt; 0 or &gt; 100
- Show approve button on electronic pending (use complete-electronic)
- Recalculate wallet fee on admin UI for old bookings — read stored payment fields only
- Build customer wallet top-up creation on admin app (customer app only)

---

## PROMPT END
