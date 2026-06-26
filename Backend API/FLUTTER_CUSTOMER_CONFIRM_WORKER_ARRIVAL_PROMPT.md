# Flutter Customer App — Confirm Worker Arrival (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

**Backend reference:** `BOOKING_WALLET_ARRIVAL.md`

---

## PROMPT START

Implement **Customer Worker Arrival Confirmation** in the **Bareq Customer** Flutter app using **Clean Architecture** (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`

This is an **optional** customer action. It is **not** a booking status — do not add a new status value or local enum for “arrived”.

---

## Business rules

| Rule | Detail |
|------|--------|
| Who | **Customer** only, JWT owner of the booking |
| When | Booking `status` must be **OnTheWay (2)** |
| Once only | `isWorkerArrivalConfirmed` must be `false` |
| Wallet | If booking was paid with wallet and amount is **reserved but not captured**, confirming arrival **captures** the hold |
| If customer skips | When booking later becomes **Completed**, server **auto-captures** wallet if still reserved |
| Notifications | Server sends Arabic in-app notification on confirm (+ wallet capture notification if applicable) |

### Booking statuses (unchanged — do not add new status)

| Value | Name |
|------:|------|
| 0 | Pending |
| 1 | Approved |
| 2 | OnTheWay |
| 3 | Completed |
| 4 | Canceled |
| 5 | Rejected |

Arrival = separate flags: `isWorkerArrivalConfirmed`, `workerArrivalConfirmedAt`.

---

## API

### Confirm arrival

```http
PATCH /api/Bookings/{bookingId}/ConfirmArrival
Authorization: Bearer {customerToken}
```

- **No request body**
- **Customer** role required

**Success (200):** full updated `BookingDTO`:

```json
{
  "id": 42,
  "status": 2,
  "isWorkerArrivalConfirmed": true,
  "workerArrivalConfirmedAt": "2026-06-04T14:30:00Z",
  "walletAmountReserved": true,
  "walletAmountCaptured": true,
  "walletCapturedAt": "2026-06-04T14:30:00Z",
  "totalPrice": 105.00
}
```

**Errors:**

| HTTP | When | UI |
|------|------|-----|
| 401 | No token | Redirect to login |
| 403 | Not booking owner | "لا يمكنك تأكيد هذا الحجز" |
| 400 | Wrong status, already confirmed, invalid wallet state | Show `message` from body |
| 404 | Booking not found | Not found screen |

Example 400 body:

```json
{ "message": "Arrival can only be confirmed when the booking is on the way." }
```

### Reload booking (before/after)

```http
GET /api/Bookings/GetBookingById/{id}
Authorization: Bearer {token}
```

Customer may also use:

```http
GET /api/Bookings/User/{userId}?page=1&pageSize=20
```

### Refresh wallet after confirm (wallet bookings)

```http
GET /api/v1/wallet
```

After capture, `balance` stays lower (reserved moved to captured), `reservedBalance` decreases.

---

## Booking model (data layer)

Extend `BookingModel` / map to domain `Booking`:

```dart
bool isWorkerArrivalConfirmed;
DateTime? workerArrivalConfirmedAt;
bool walletAmountReserved;
bool walletAmountCaptured;
DateTime? walletCapturedAt;
int status; // 0-5 only
```

JSON (camelCase from API):

- `isWorkerArrivalConfirmed`
- `workerArrivalConfirmedAt`
- `walletAmountReserved`
- `walletAmountCaptured`
- `walletCapturedAt`

---

## Clean Architecture

```
features/booking/
├── domain/
│   ├── entities/booking.dart
│   ├── repositories/booking_repository.dart
│   └── usecases/confirm_worker_arrival.dart
├── data/
│   ├── models/booking_model.dart
│   ├── datasources/booking_remote_datasource.dart
│   └── repositories/booking_repository_impl.dart
└── presentation/
    ├── cubit/booking_detail_cubit.dart   // or extend existing
    └── widgets/confirm_arrival_section.dart
```

### Use case

`ConfirmWorkerArrival(bookingId)` → calls repository → returns `Either<Failure, Booking>`.

On success:

1. Emit updated booking state
2. Optionally invalidate wallet summary cache / call `GetWalletSummary`
3. Show success snackbar (Arabic)

---

## UI — Booking detail screen

### When to show the action

Show primary button **تأكيد وصول العاملة** only when **all** are true:

```dart
booking.status == 2 && // OnTheWay
!booking.isWorkerArrivalConfirmed &&
booking.userId == currentUserId;
```

### After confirmed

- Hide the button
- Show success row/card:
  - **تم تأكيد وصول العاملة**
  - Subtitle: formatted `workerArrivalConfirmedAt` (local timezone, Arabic date)
- Optional checkmark icon

### Wallet payment hints (same screen)

| Condition | Arabic label |
|-----------|----------------|
| `walletAmountReserved && !walletAmountCaptured` | المبلغ محجوز من محفظتك — يُخصم عند تأكيد الوصول أو إكمال الخدمة |
| `walletAmountCaptured` | تم خصم المبلغ من المحفظة |
| After confirm + captured | Refresh wallet chip in app bar / profile |

Explain briefly under the button (optional):

> يمكنك تأكيد وصول العاملة الآن. إذا لم تؤكد، سيتم خصم المبلغ تلقائياً عند إكمال الخدمة.

### Status chip (unchanged)

Still show status **في الطريق** while `status == 2`, even after arrival confirmed.

### Loading / confirm dialog

1. User taps **تأكيد وصول العاملة**
2. Optional confirmation dialog:
   - Title: تأكيد وصول العاملة
   - Body: هل وصلت العاملة إلى موقع الخدمة؟
   - Confirm: تأكيد
3. Show loading on button
4. `PATCH ConfirmArrival`
5. On success → update UI from response body (do not rely only on local flag)

### Do NOT show button when

- `status` is Pending, Approved, Completed, Canceled, Rejected
- `isWorkerArrivalConfirmed == true`
- User is not the booking owner

---

## Notifications (server-driven)

After successful confirm, customer may receive:

| Arabic | Meaning |
|--------|---------|
| تم تأكيد وصول العاملة إلى موقع الخدمة. | Arrival confirmed |
| تم خصم قيمة الحجز من المحفظة. | Wallet captured (if wallet booking) |

Listen via existing notification bell / SignalR (`ReceiveNotification`). No extra client API call required beyond confirm.

---

## Booking list (optional badge)

On **My Bookings** list, for `status == 2`:

- If `!isWorkerArrivalConfirmed` → small badge **بانتظار تأكيد الوصول**
- If `isWorkerArrivalConfirmed` → **تم تأكيد الوصول**

---

## Integration with wallet flow

1. Customer creates booking with `"paymentMethod": "Wallet"` → amount **reserved**
2. Company sets **Approved** → **OnTheWay**
3. Customer opens detail → taps **تأكيد وصول العاملة** → **capture**
4. Later company/customer sets **Completed** → no double charge (server guards `walletAmountCaptured`)

If customer never confirms:

- On **Completed**, server captures automatically — UI should refresh booking + wallet on status change notification or poll.

---

## Error messages (map to Arabic UX)

| API message (English) | Suggested Arabic |
|----------------------|------------------|
| Arrival can only be confirmed when the booking is on the way. | يمكن تأكيد الوصول فقط عندما تكون الحالة «في الطريق». |
| Worker arrival is already confirmed. | تم تأكيد الوصول مسبقاً. |
| Wallet reservation is not valid for capture. | حالة الدفع بالمحفظة غير صالحة. تأكد من الحجز. |

---

## Testing checklist

- [ ] Button visible only for OnTheWay + not confirmed + own booking
- [ ] Confirm → 200 → flags updated, button hidden
- [ ] Second confirm attempt → 400 already confirmed
- [ ] Confirm when Approved → 400
- [ ] Wallet booking: after confirm, `walletAmountCaptured == true` and wallet summary refreshed
- [ ] Non-wallet booking: confirm works, no wallet capture UI needed
- [ ] Complete booking without prior confirm → wallet still captured (server)
- [ ] RTL layout for button and confirmed state

---

## Do NOT

- Add a new booking status like “Arrived” or `status: 6`
- Call `ConfirmArrival` from company or admin flows
- Set `isWorkerArrivalConfirmed` locally without API success
- Deduct wallet balance in the app — server only
- Hide OnTheWay status after confirm (status stays 2 until Completed)

---

## PROMPT END
