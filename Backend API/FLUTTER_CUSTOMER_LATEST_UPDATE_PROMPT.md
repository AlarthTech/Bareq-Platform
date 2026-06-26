# Bareq Customer App — Latest Update Prompt (June 2026)

Use this **after** `FLUTTER_CUSTOMER_APP_IMPLEMENTATION_PROMPT.md`, or paste alone if the app already exists and you only need **recent API changes**.

Copy everything below **`## PROMPT START`**.

---

## PROMPT START

You are updating the **Bareq Customer** Flutter app (Clean Architecture: Presentation → Domain → Data) for the **current production API**:

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Auth:** `Authorization: Bearer {token}` — always `"userType": "Customer"` on login

---

## 1. Platform fee & price preview (before booking)

**Full prompt:** `FLUTTER_CUSTOMER_PLATFORM_FEE_PROMPT.md`

### Price preview (server-calculated)

```http
POST /api/v1/bookings/price-preview
Authorization: Bearer {token}
```

```json
{
  "companyId": 11,
  "workerId": 10,
  "workTypeId": 9,
  "bookingDate": "2026-06-15T00:00:00Z",
  "startDate": "08:00",
  "endDate": "17:00",
  "isMonthly": false
}
```

Show breakdown before confirm:

```
سعر الخدمة        XX.XX د.ل
رسوم المنصة         X.XX د.ل
─────────────────────────────
الإجمالي          XX.XX د.ل
```

### Create booking

- Send `isMonthly` + `paymentMethod` (optional: `"Wallet"`, `"Cash"`, etc.)
- **Do not** send price fields — server stores `servicePrice`, `platformFeeAmount`, `totalPrice`

### Booking list/detail — extend model

```dart
double servicePrice;
double platformFeeAmount;
double totalPrice;
bool isMonthlyPricing;
```

---

## 2. Wallet payment — reserve / capture (IMPORTANT)

**Full prompt:** `FLUTTER_CUSTOMER_WALLET_PROMPT.md` (read with corrections below)

### Corrected business rules

| Old (wrong) | Current API |
|-------------|-------------|
| Balance deducted immediately on `CreateBooking` | **Reserve** hold on create; **capture** later |
| Cash top-up | **BankCard** + **BankTransfer** only |
| `POST /api/v1/wallet/top-up` with Cash | Use `POST /api/v1/wallet/top-up/bank-card` or bank transfer |

### Wallet summary

```http
GET /api/v1/wallet
```

```json
{
  "balance": 150.00,
  "reservedBalance": 25.00,
  "availableBalance": 125.00,
  "isWalletPaymentEnabled": true,
  "walletPaymentFeePercentage": 5
}
```

- **Available** = spendable (`balance`)
- **Reserved** = held for pending wallet bookings (not spendable)

### Booking with wallet

```json
POST /api/Bookings/CreateBooking
{
  "...": "...",
  "paymentMethod": "Wallet"
}
```

- On success: booking **Pending**, wallet **reserved** (not fully charged)
- Show badge: **محجوز من المحفظة**
- Refresh wallet summary after create

### Insufficient balance

API returns 400 with:

```json
{
  "message": "Insufficient wallet balance...",
  "walletBalance": 50,
  "requiredAmount": 105
}
```

Show top-up CTA — do not deduct locally.

### Bank card top-up (backward compatible)

Legacy app may call:

```http
POST /api/v1/wallet/top-up
{ "requestedAmount": 100, "paymentMethod": "BankCard" }
```

Server routes **BankCard** to the bank-card flow. Prefer:

```http
POST /api/v1/wallet/top-up/bank-card
{ "amount": 100 }
```

Response includes `paymentUrl` → open WebView → poll `GET /api/v1/wallet/top-ups/{id}` until `Completed`.

### Bank transfer top-up

```http
POST /api/v1/wallet/top-up
{
  "requestedAmount": 100,
  "paymentMethod": "BankTransfer",
  "transferReferenceNumber": "...",
  "transferReceiptImageUrl": "..."
}
```

Show active account from `GET /api/v1/wallet/bank-transfer-account`.

---

## 3. Confirm worker arrival (customer only)

**Full prompt:** `FLUTTER_CUSTOMER_CONFIRM_WORKER_ARRIVAL_PROMPT.md`

When booking status = **OnTheWay (2)**:

```http
PATCH /api/Bookings/{id}/ConfirmArrival
Authorization: Bearer {token}
```

No body. **Customer owner only.**

Effects:

- `isWorkerArrivalConfirmed = true`
- If wallet booking: **captures** reserved amount
- In-app notification (Arabic): تم تأكيد وصول العاملة إلى موقع الخدمة

### UI

- Show button **تأكيد وصول العاملة** only when:
  - `status == 2` (OnTheWay)
  - `!isWorkerArrivalConfirmed`
- Hide after confirmed; show **تم تأكيد الوصول** + timestamp
- If wallet reserved and not captured → explain that payment completes on confirm or when service completes

### Booking model — add fields

```dart
bool isWorkerArrivalConfirmed;
DateTime? workerArrivalConfirmedAt;
bool walletAmountReserved;
bool walletAmountCaptured;
DateTime? walletCapturedAt;
```

### Wallet lifecycle (customer messaging)

| State | Arabic hint |
|-------|-------------|
| Reserved, not captured | المبلغ محجوز من محفظتك |
| Captured | تم خصم المبلغ من المحفظة |
| Canceled before capture | تم إرجاع المبلغ المحجوز |
| Canceled after capture | تم استرداد المبلغ إلى المحفظة |

Capture also happens automatically when booking becomes **Completed** if customer did not confirm arrival.

---

## 4. In-app notifications

**Full prompt:** `FLUTTER_CUSTOMER_NOTIFICATIONS_PROMPT.md`

- REST: `/api/Notifications/*`
- SignalR: `http://102.203.200.55:5545/hubs/notifications` (JWT)
- Customer receives booking status updates (confirmed, on the way, completed, cancelled, rejected)
- Bell + unread badge + mark read
- Tap notification → open booking detail when `relatedEntityId` is booking id

**Note:** No notification when customer **creates** booking (by design).

---

## 5. Reports (البلاغات)

### Worker / company reports

**Full prompt:** `FLUTTER_CUSTOMER_REPORTS_PROMPT.md`

```http
POST /api/Reports/CreateReport
GET  /api/Reports/GetMyReports?page=1&pageSize=20
```

Report worker (`targetType: 1`) or company (`targetType: 2`).

### Booking reports (بلاغ على حجز) — NEW

**Full prompt:** `FLUTTER_CUSTOMER_BOOKING_REPORTS_PROMPT.md`

```http
POST /api/BookingReports
GET  /api/BookingReports/MyReports?page=1&pageSize=20
GET  /api/BookingReports/Booking/{bookingId}?page=1&pageSize=20
```

- Report a **specific booking** (not worker/company profile)
- Allowed booking statuses: Pending, Approved, OnTheWay, Rejected
- Blocked: Completed, Canceled
- One active report per booking (Open/InReview)
- Notification type **22** → open booking report detail (`relatedEntityId` = report id)

---

## 6. Reviews — no service picker

**Full prompt:** `FLUTTER_CUSTOMER_WORKER_RATING_PROMPT.md` (updated)

Create review body:

```json
{
  "bookingId": 42,
  "workerId": 10,
  "rating": 5,
  "comment": "optional"
}
```

**Remove** `serviceId` / cleaning services dropdown — API no longer uses it.

---

## 7. Home screen workers (server-driven)

**Full prompt:** `FLUTTER_HOME_SCREEN_WORKERS_PROMPT.md`

```http
GET /api/v1/workers/available?date=YYYY-MM-DD&page=1&pageSize=20
GET /api/v1/workers/top-rated?page=1&pageSize=20
```

Do **not** compute availability from raw booking lists on the client.

---

## 8. Create booking — conflict rules

**Prompt:** `FLUTTER_CREATE_BOOKING_FIX_PROMPT.md`

- **409** = worker busy or same customer already booked that day
- Show Arabic `detail` from `ProblemDetails`
- `startDate` / `endDate` = `"HH:mm"` strings
- Send `userLocationId` **or** `address`

---

## 9. Forgot password

**Full prompt:** `FLUTTER_CUSTOMER_FORGOT_PASSWORD_PROMPT.md`

- `"userType": "Customer"` on all 3 steps
- `email` field accepts email **or** phone (OTP always sent to registered email)

---

## 10. Testing checklist (additions)

- [ ] Price preview matches create booking total
- [ ] Wallet create booking → reserved balance increases, available decreases
- [ ] Confirm arrival on OnTheWay → capture + wallet refresh
- [ ] Complete booking without confirm → auto-capture
- [ ] Cancel pending wallet booking → release hold
- [ ] Bank card top-up via WebView + poll
- [ ] Legacy `top-up` + BankCard still works
- [ ] Notifications for status changes (not on create)
- [ ] Review without serviceId

---

## Related files (implementation order)

| # | File |
|---|------|
| Base | `FLUTTER_CUSTOMER_APP_IMPLEMENTATION_PROMPT.md` |
| API breaking | `FLUTTER_API_UPDATE_PROMPT.md` |
| This update | `FLUTTER_CUSTOMER_LATEST_UPDATE_PROMPT.md` |
| Home | `FLUTTER_HOME_SCREEN_WORKERS_PROMPT.md` |
| Pricing | `FLUTTER_CUSTOMER_PLATFORM_FEE_PROMPT.md` |
| Wallet | `FLUTTER_CUSTOMER_WALLET_PROMPT.md` |
| Confirm arrival | `FLUTTER_CUSTOMER_CONFIRM_WORKER_ARRIVAL_PROMPT.md` |
| Notifications | `FLUTTER_CUSTOMER_NOTIFICATIONS_PROMPT.md` |
| Reports (worker/company) | `FLUTTER_CUSTOMER_REPORTS_PROMPT.md` |
| Booking reports | `FLUTTER_CUSTOMER_BOOKING_REPORTS_PROMPT.md` |
| Reviews | `FLUTTER_CUSTOMER_WORKER_RATING_PROMPT.md` |
| Booking fix | `FLUTTER_CREATE_BOOKING_FIX_PROMPT.md` |

---

## PROMPT END
