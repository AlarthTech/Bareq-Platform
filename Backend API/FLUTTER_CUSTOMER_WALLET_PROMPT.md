# Flutter Customer App — Wallet Payment (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

Implement **Wallet Payment** in the **Bareq Customer** Flutter app using **Clean Architecture** (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Backend reference:** `WALLET_PAYMENT_IMPLEMENTATION.md`

**Customer JWT required** on all endpoints below.

**Important:** Top-up methods are **only** `BankCard` and `BankTransfer`. **Do not** show Cash.

---

## Business rules

| Rule | Detail |
|------|--------|
| Top-up methods | **BankCard**, **BankTransfer** only — no Cash |
| Bank card | Pending → gateway success → wallet credited automatically (poll status) |
| Bank transfer | Pending until **admin approves** — show active bank account from API |
| Wallet booking fee | Percentage of booking `totalPrice` (from server settings) |
| Payable | `requiredAmount = bookingTotal + walletFee` (server calculates on create) |
| Booking | Send `"paymentMethod": "Wallet"` on `CreateBooking` — **reserve** on create; **capture** on arrival confirm or completion |
| Balance | Never calculate or deduct locally — only display API values |

---

## 1. Feature structure (Clean Architecture)

```
features/wallet/
├── domain/
│   ├── entities/
│   ├── repositories/wallet_repository.dart
│   └── usecases/
│       ├── get_wallet_summary.dart
│       ├── get_wallet_transactions.dart
│       ├── get_bank_transfer_account.dart
│       ├── create_wallet_top_up.dart
│       ├── get_top_up_status.dart
│       └── get_wallet_booking_quote.dart
├── data/
│   ├── models/
│   ├── datasources/wallet_remote_datasource.dart
│   └── repositories/wallet_repository_impl.dart
└── presentation/
    ├── cubit/wallet_cubit.dart
    ├── pages/wallet_screen.dart
    ├── pages/wallet_top_up_screen.dart
    ├── pages/wallet_transactions_screen.dart
    └── widgets/
```

Integrate wallet into **booking** payment step and **profile**.

---

## 2. Customer APIs

### Wallet summary

```http
GET /api/v1/wallet
Authorization: Bearer {token}
```

```json
{
  "walletId": 1,
  "customerId": 10,
  "balance": 150.00,
  "currency": "LYD",
  "isActive": true,
  "isWalletPaymentEnabled": true,
  "walletPaymentFeePercentage": 5
}
```

Use `isWalletPaymentEnabled` to show/hide **Pay with Wallet** in booking.

### Transaction history

```http
GET /api/v1/wallet/transactions?page=1&pageSize=20
```

**PagedResult** — parse `items`, `hasNextPage`, etc.

| type (API) | Arabic label |
|------------|----------------|
| BankCardTopUp | شحن بطاقة |
| BankTransferTopUp | تحويل بنكي |
| WalletPayment | دفع حجز |
| WalletRefund | استرداد |
| ManualCredit | إضافة رصيد |

### Active bank account (for transfer UI)

```http
GET /api/v1/wallet/bank-transfer-account
```

**404** if admin has not configured an active account — disable bank transfer option with message.

```json
{
  "id": 1,
  "bankName": "...",
  "accountHolderName": "...",
  "accountNumber": "...",
  "iban": "...",
  "branchName": "...",
  "instructions": "...",
  "isActive": true
}
```

### Test only — instant bank card charge (no gateway)

Use while payment gateway is not integrated. Requires backend flag `EnableTestInstantBankCardTopUp=true`.

```http
POST /api/v1/wallet/test/bank-card-charge
{ "amount": 150 }
```

Response: `{ topUpId, status: "Completed", creditedAmount, walletBalance }` — balance updates immediately.

### Bank card top-up (automatic after gateway)

```http
POST /api/v1/wallet/top-up/bank-card
Content-Type: application/json
```

```json
{ "amount": 100 }
```

**Response (201):**

```json
{
  "message": "Wallet top-up payment started successfully.",
  "topUpId": 15,
  "paymentUrl": "https://payment-gateway-url.com/pay?..."
}
```

No admin approval. Backend credits wallet when the gateway calls the server callback.

### Bank transfer top-up

```http
POST /api/v1/wallet/top-up
Content-Type: application/json
```

**Bank transfer:**

```json
{
  "requestedAmount": 100,
  "paymentMethod": "BankTransfer",
  "transferReferenceNumber": "REF-123",
  "transferReceiptImageUrl": "/Uploads/receipt.jpg",
  "notes": "optional"
}
```

**Response (201):**

```json
{
  "id": 12,
  "customerId": 10,
  "requestedAmount": 100,
  "approvedAmount": null,
  "paymentMethod": "BankTransfer",
  "status": "Pending",
  "transferReferenceNumber": "REF-123",
  "transferReceiptImageUrl": "...",
  "gatewayPaymentReference": null,
  "notes": null,
  "createdAt": "...",
  "reviewedAt": null,
  "completedAt": null
}
```

**Statuses:** `Pending`, `Completed` (bank card), `Approved` (bank transfer), `Rejected`, `Failed`

### Top-up status (poll)

```http
GET /api/v1/wallet/top-ups/{id}
```

---

## 3. Top-up UI flows

### A — Bank card (بطاقة بنكية)

1. User enters amount → `POST /api/v1/wallet/top-up/bank-card` with `{ "amount": N }`
2. Open `paymentUrl` in WebView / native SDK
3. Gateway notifies backend: `POST /api/v1/payments/wallet-top-up/callback` (server-side; not from the app)
4. App polls `GET /api/v1/wallet/top-ups/{id}` every 5–10s until `status` is `Completed` or `Failed`
5. Refresh wallet summary on `Completed`

### B — Bank transfer (تحويل بنكي)

1. `GET /api/v1/wallet/bank-transfer-account` — display bank details (copy-friendly UI)
2. User enters amount, reference, uploads receipt image → get URL from your upload API
3. `POST /api/v1/wallet/top-up` with `BankTransfer`
4. Show **في انتظار موافقة الإدارة** — poll status until `Approved` or `Rejected`
5. On `Approved`, refresh balance (admin may credit different `approvedAmount`)

### Entry points

- Profile → **المحفظة**
- Booking payment step → **شحن المحفظة** if insufficient balance

---

## 4. Booking with wallet

### Price preview (existing)

```http
POST /api/v1/bookings/price-preview
```

Use `totalPrice` as booking total.

### Display before confirm (client preview only)

From `GET /api/v1/wallet`:

- `walletPaymentFeePercentage`
- Show: service breakdown + **رسوم الدفع بالمحفظة** + **المبلغ المطلوب من المحفظة**
- Compare `balance` vs required — disable confirm if insufficient

### Confirm booking

```http
POST /api/Bookings/CreateBooking
```

Add to existing body:

```json
{
  "paymentMethod": "Wallet",
  "companyId": 1,
  "workerId": 2,
  ...
}
```

**Do not** send price fields.

**Success (201) — wallet:**

```json
{
  "message": "Booking confirmed successfully using wallet.",
  "bookingId": 123,
  "bookingTotal": 100,
  "walletFee": 5,
  "paidAmount": 105,
  "remainingWalletBalance": 45
}
```

**Insufficient balance (400):**

```json
{
  "message": "Insufficient wallet balance. Please charge your wallet to continue.",
  "walletBalance": 80,
  "requiredAmount": 105
}
```

Show CTA → top-up screen.

**Wallet disabled (400):**

```json
{
  "message": "Wallet payment is currently unavailable."
}
```

Hide wallet option when `isWalletPaymentEnabled == false`.

---

## 5. Screens

| Screen | Route | Actions |
|--------|-------|---------|
| Wallet home | `/wallet` | Balance, شحن المحفظة, سجل المعاملات |
| Top-up | `/wallet/top-up` | Choose BankCard / BankTransfer |
| Bank transfer form | `/wallet/top-up/transfer` | Show bank account + form |
| Top-up status | `/wallet/top-up/{id}` | Pending / success / failed |
| Transactions | `/wallet/transactions` | Paginated list |
| Booking pay step | existing flow | Wallet option + fee breakdown |

---

## 6. Domain failures

```dart
sealed class WalletFailure {}

class WalletDisabledFailure extends WalletFailure {}
class InsufficientWalletBalanceFailure extends WalletFailure {
  final double walletBalance;
  final double requiredAmount;
}
class WalletNetworkFailure extends WalletFailure {}
class NoBankAccountConfiguredFailure extends WalletFailure {}
```

Map Dio 400/404 bodies to failures.

---

## 7. Payment method constants

```dart
class WalletTopUpMethods {
  static const bankCard = 'BankCard';
  static const bankTransfer = 'BankTransfer';
  static const wallet = 'Wallet'; // booking only
}
```

Reject any UI path that sends `Cash` or `ElectronicPayment`.

---

## 8. Testing checklist

- [ ] Wallet summary loads with balance
- [ ] Transactions paginate correctly
- [ ] Bank transfer shows active account
- [ ] Bank transfer top-up stays Pending until Approved
- [ ] Bank card: `POST top-up/bank-card` → open `paymentUrl` → poll `GET top-ups/{id}` until Completed/Failed
- [ ] Bank card does not require admin approval
- [ ] Cash option not shown anywhere
- [ ] Booking with Wallet deducts (balance decreases)
- [ ] Insufficient balance shows top-up CTA
- [ ] Wallet hidden when disabled in settings
- [ ] Cancel booking refunds balance (server-side)

---

## 9. Do NOT

- Offer **Cash** top-up
- Credit wallet before API success
- Send prices in `CreateBooking`
- Compute wallet fee for charging (display estimate OK; server is source of truth on pay)
- Call admin endpoints from customer app

---

## PROMPT END
