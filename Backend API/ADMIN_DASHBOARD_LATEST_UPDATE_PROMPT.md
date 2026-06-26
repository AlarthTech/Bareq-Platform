# Bareq Admin Dashboard — Latest Update Prompt (June 2026)

Use this **after** the base prompt in `ADMIN_DASHBOARD_IMPLEMENTATION_PROMPT.md`, or paste it alone if the dashboard already exists and you only need deltas.

Copy everything below **`## PROMPT START`**.

---

## PROMPT START

You are updating the **Bareq Admin Dashboard** to match the **current production API** (`http://102.203.200.55:5545`).

Apply all sections below. Keep **RTL Arabic**, existing auth, and TanStack Query patterns.

---

## 1. Sidebar — add Financial & Operations items

Extend navigation:

```
المالية
  ├── رسوم المنصة           → /settings/platform-fee
  ├── إعدادات المحفظة       → /settings/wallet
  └── طلبات شحن المحفظة    → /wallet/top-ups

العمليات
  ├── الإشعارات (bell)      → top bar (not a route)
  ├── بلاغات العملاء        → /reports
  └── بلاغات الحجوزات       → /booking-reports
```

Full module prompts:

| Feature | File |
|---------|------|
| Platform fee | `ADMIN_DASHBOARD_PLATFORM_FEE_PROMPT.md` |
| Wallet admin | `ADMIN_DASHBOARD_WALLET_PROMPT.md` |
| Notifications bell + SignalR | `ADMIN_DASHBOARD_NOTIFICATIONS_PROMPT.md` |
| Customer reports (worker/company) | `ADMIN_REPORTS_IMPLEMENTATION_PROMPT.md` |
| Booking reports | `ADMIN_DASHBOARD_BOOKING_REPORTS_PROMPT.md` |

---

## 2. Bookings module — pricing + wallet flags (IMPORTANT)

### Extend `BookingDTO` in TypeScript

```typescript
interface Booking {
  // ...existing fields...
  servicePrice: number;
  platformFeeAmount: number;
  totalPrice: number;
  isMonthlyPricing: boolean;
  isWorkerArrivalConfirmed: boolean;
  workerArrivalConfirmedAt?: string | null;
  walletAmountReserved: boolean;
  walletAmountCaptured: boolean;
  walletCapturedAt?: string | null;
}
```

### List & detail UI

- Show column **الإجمالي** = `totalPrice` LYD
- Detail card **تفاصيل السعر**:
  - سعر الخدمة = `servicePrice`
  - رسوم المنصة = `platformFeeAmount`
  - الإجمالي = `totalPrice`
  - Badge if monthly: `isMonthlyPricing`
- If all prices are `0` on old bookings → badge “تسعير قديم — غير متوفر”

### Wallet payment badges (admin read-only)

| Flags | Arabic badge |
|-------|----------------|
| `walletAmountReserved && !walletAmountCaptured` | محجوز من المحفظة |
| `walletAmountCaptured` | تم الخصم من المحفظة |
| `isWorkerArrivalConfirmed` | تم تأكيد وصول العاملة |

**Admin does not call** `PATCH /api/Bookings/{id}/ConfirmArrival` (customer-only).

### Wallet behavior admins must understand (support / status changes)

Statuses remain **0–5 only** (no new status for arrival).

| Event | Wallet effect |
|-------|----------------|
| Customer creates booking with `paymentMethod: "Wallet"` | **Reserve** hold (not full capture); booking stays Pending |
| Customer confirms arrival (`OnTheWay`) | **Capture** if not captured |
| Status → **Completed** | Auto-**capture** if reserved and not captured |
| Status → **Canceled** / **Rejected** | **Release** hold if not captured; **refund** if already captured |

When admin forces status to Canceled/Rejected on a captured wallet booking, backend refunds automatically.

---

## 3. Platform fee settings

Implement per **`ADMIN_DASHBOARD_PLATFORM_FEE_PROMPT.md`**:

```http
GET  /api/v1/admin/platform-fee
PUT  /api/v1/admin/platform-fee
```

Body: `{ "amount": 0 }` (fixed LYD added to new bookings only).

---

## 4. Wallet admin (updated rules)

Implement per **`ADMIN_DASHBOARD_WALLET_PROMPT.md`** with these **corrections**:

| Old assumption | Current API |
|----------------|-------------|
| Wallet deducted immediately on booking | **Reserve** on create; **capture** on completion or customer arrival confirm |
| Only cash top-ups | **Bank transfer** queue + **bank card** gateway confirm |

### Key admin endpoints

```http
GET  /api/v1/admin/payment-settings/wallet
PUT  /api/v1/admin/payment-settings/wallet

GET  /api/v1/admin/wallet/top-ups/bank-transfers?status=Pending&page=1&pageSize=20
GET  /api/v1/admin/wallet/top-ups/bank-transfers/{id}
POST /api/v1/admin/wallet/top-ups/bank-transfers/{id}/approve
POST /api/v1/admin/wallet/top-ups/bank-transfers/{id}/reject

POST /api/v1/admin/wallet/top-ups/{id}/confirm-bank-card
POST /api/v1/admin/wallet/top-ups/{id}/fail-bank-card

POST /api/v1/admin/wallet/wallets/{customerId}/credit
POST /api/v1/admin/wallet/wallets/bulk-credit
```

Gateway callback (not admin UI): `POST /api/v1/payments/wallet-top-up/callback`

### Top-up tabs

| Tab | `paymentMethod` | Admin action |
|-----|-----------------|--------------|
| تحويل بنكي | `BankTransfer` | Approve / Reject |
| بطاقة بنكية | `BankCard` | Confirm / Fail (or wait for gateway callback) |

---

## 5. In-app notifications (admin bell)

Implement per **`ADMIN_DASHBOARD_NOTIFICATIONS_PROMPT.md`**:

- REST: `/api/Notifications/*`
- SignalR: `http://102.203.200.55:5545/hubs/notifications` with JWT
- Events: new company pending, new worker pending, health cert expired, customer reports
- Also listen for wallet/booking notification types if shown in feed (optional)

---

## 6. Reports modules

### Worker / company reports

Implement per **`ADMIN_REPORTS_IMPLEMENTATION_PROMPT.md`**:

```http
GET   /api/Reports/GetReports?page=1&pageSize=20
GET   /api/Reports/GetReportById/{id}
PATCH /api/Reports/UpdateReportStatus/{id}
DELETE /api/Reports/DeleteReport/{id}
```

### Booking reports (NEW)

Implement per **`ADMIN_DASHBOARD_BOOKING_REPORTS_PROMPT.md`**:

```http
GET   /api/BookingReports?status=0&bookingId=80&page=1&pageSize=20
GET   /api/BookingReports/{id}
PATCH /api/BookingReports/{id}/Status
```

- Filters: `status`, `bookingId`, `customerId`, `companyId`, `workerId`, `fromDate`, `toDate`
- Admin status: InReview (1), Resolved (2), Rejected (3) — `adminResolutionNotes` required for 2/3
- No delete endpoint
- Notification type **21** → navigate to `/booking-reports/{relatedEntityId}`

---

## 7. Reviews module — remove service fields

`ReviewDTO` no longer has `serviceId` / `serviceName`. Create review payload is only:

```json
{ "bookingId", "workerId", "rating", "comment" }
```

Admin reviews list: show booking id, worker, customer, rating, comment.

---

## 8. Testing checklist (add to QA)

- [ ] Platform fee save + shown on new bookings
- [ ] Wallet settings toggle + fee %
- [ ] Bank transfer top-up approve/reject
- [ ] Bank card top-up confirm (admin or callback)
- [ ] Manual wallet credit by `customerId`
- [ ] Booking detail shows wallet reserve/capture badges
- [ ] Admin cancel wallet booking → refund/release in API
- [ ] Notification bell + unread count + mark read
- [ ] Worker/company reports status workflow
- [ ] Booking reports list + filters + status update with required notes

---

## PROMPT END
