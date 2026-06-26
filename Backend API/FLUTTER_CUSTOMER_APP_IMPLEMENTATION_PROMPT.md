# Bareq Customer App — Full Flutter Implementation Prompt

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

You are building the **Bareq Customer** mobile app — Flutter app for end users to discover cleaning companies/workers, book services, pay (including **wallet**), track bookings, receive notifications, and manage their profile.

**Mandatory:** **Clean Architecture** — strict layer separation:

```
Presentation → Domain → Data
```

- UI **never** calls APIs directly
- Use **UseCases** returning `Either<Failure, T>`
- **Entities** in domain (no JSON annotations)
- **DTOs/models** in data layer only

**Recommended stack:** Flutter 3.x · Dart 3 · **flutter_bloc** or **Cubit** · **Dio** · **get_it** / **injectable** · **go_router** · **intl** (AR primary, RTL) · **google_maps_flutter** (locations) · **signalr_netcore** or equivalent (notifications)

**API Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Health:** `GET /health`

---

## 1. Authentication

### Login

```http
POST /api/AppUsers/Login
Content-Type: application/json
```

```json
{
  "username": "email-or-phone",
  "password": "...",
  "userType": "Customer"
}
```

**Must** send `"userType": "Customer"`.

**Success (200):**

```json
{
  "success": true,
  "message": "تم تسجيل الدخول بنجاح",
  "token": "eyJ...",
  "user": {
    "id": 10,
    "fullName": "...",
    "phone": "...",
    "email": "...",
    "userTypeId": 2,
    "userTypeName": "Customer",
    "createdAt": "..."
  }
}
```

- Store JWT securely (`flutter_secure_storage`)
- Attach `Authorization: Bearer {token}` to protected routes
- On **401** → logout → login screen
- Reject login if `userTypeName != "Customer"`

### Registration

Use existing customer registration endpoint from Swagger (`POST /api/AppUsers/...` — verify in Swagger).

### Forgot password

See **`FLUTTER_CUSTOMER_FORGOT_PASSWORD_PROMPT.md`**.

---

## 2. Pagination (required for ALL lists)

List endpoints return **`PagedResult<T>`**, not a root array:

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "totalCount": 0,
  "totalPages": 0,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

Query: `page` (default 1), `pageSize` (default 20, max 50).

Implement generic `PagedResult<T>` in `core/` and infinite scroll when `hasNextPage`.

**Foundation details:** `FLUTTER_API_UPDATE_PROMPT.md` §1.

---

## 3. App navigation (suggested)

| Tab / route | Feature |
|-------------|---------|
| `/home` | Home, date picker, available + top-rated workers |
| `/companies` | Browse verified companies |
| `/bookings` | My bookings list |
| `/notifications` | In-app notifications |
| `/profile` | Account, wallet, locations, settings |

**Deep links:** notification tap → `/bookings/{id}`.

---

## 4. Home screen — workers (backend-driven)

**Do NOT** compute availability from booking lists on the client.

| Section | API |
|---------|-----|
| Available workers | `GET /api/v1/workers/available?date={yyyy-MM-dd}&page=&pageSize=` |
| Top rated workers | `GET /api/v1/workers/top-rated?page=&pageSize=` |

- Anonymous (no JWT required)
- Display `availabilityLabel` from API as-is
- Refresh available section when user changes date
- Worker card → worker detail → start booking flow

**Full spec:** `FLUTTER_HOME_SCREEN_WORKERS_PROMPT.md`

---

## 5. Companies & workers (legacy + detail)

| Action | API |
|--------|-----|
| Active companies | `GET /api/Companies/GetActiveCompanies?page=&pageSize=` |
| Company work types | `GET /api/WorkTypes/GetWorkTypesByCompany/{companyId}` |
| Workers by company (JWT) | `GET /api/Workers/Company/{companyId}?page=&pageSize=` |
| Worker rating summary | `GET /api/Reviews/Worker/{workerId}/Summary` |

**Ratings UI:** `FLUTTER_CUSTOMER_RATINGS_DISPLAY_PROMPT.md`

---

## 6. Booking flow

### 6.1 Price preview (before confirm)

```http
POST /api/v1/bookings/price-preview
Authorization: Bearer {token}
```

Body: `companyId`, `workerId`, `workTypeId`, `bookingDate`, `startDate`, `endDate`, `isMonthly`

Response: `servicePrice`, `platformFeeAmount`, `totalPrice`

**Do not** calculate prices in the app.

**Full spec:** `FLUTTER_CUSTOMER_PLATFORM_FEE_PROMPT.md`

### 6.2 Create booking

```http
POST /api/Bookings/CreateBooking
Authorization: Bearer {token}
```

```json
{
  "companyId": 1,
  "workerId": 2,
  "workTypeId": 3,
  "bookingDate": "2026-06-01T10:00:00.000Z",
  "startDate": "09:00",
  "endDate": "12:00",
  "userLocationId": 5,
  "isMonthly": false,
  "paymentMethod": "Wallet"
}
```

- Send **`userLocationId` OR `address`** (at least one)
- `startDate` / `endDate` = time strings only (`"HH:mm"`)
- Omit `paymentMethod` for non-wallet flow (or send other method per your product)
- **Do not** send price fields

| Status | Action |
|--------|--------|
| 201 | Success — parse `BookingDTO` or wallet result object |
| 409 | Worker conflict — show `detail`, refresh availability |
| 400 | Validation / insufficient wallet |

**Create booking fixes:** `FLUTTER_CREATE_BOOKING_FIX_PROMPT.md`

### 6.3 My bookings

```http
GET /api/Bookings/User/{userId}?page=&pageSize=
```

**Do NOT** use `GET /api/Bookings/GetBookings` (admin only).

### 6.4 Booking detail & status

- `GET /api/Bookings/GetBookingById/{id}`
- Show `status`, `rejectionReason`, `servicePrice`, `platformFeeAmount`, `totalPrice`, map from `lat`/`lng`
- Customer can cancel pending: `PATCH /api/Bookings/UpdateStatusBooking/{id}` → `{ "status": 4 }`

### 6.5 Wallet payment

See **`FLUTTER_CUSTOMER_WALLET_PROMPT.md`**.

---

## 7. Saved locations

| Method | Path |
|--------|------|
| GET | `/api/UserLocations/GetMyLocations?page=&pageSize=` |
| POST | `/api/UserLocations/CreateUserLocation` |
| PUT | `/api/UserLocations/UpdateUserLocation/{id}` |
| DELETE | `/api/UserLocations/DeleteUserLocation/{id}` |

Body uses **`lng`** (not `lan`): `{ "locationName", "lat", "lng" }`.

Booking flow: pick location → pass `userLocationId` to create booking.

---

## 8. Favorites

```http
GET /api/Favorites/User/{userId}?page=&pageSize=
POST /api/Favorites/...   # see Swagger
DELETE /api/Favorites/...
```

---

## 9. Reviews (after completed booking)

Submit review for worker — see **`FLUTTER_CUSTOMER_WORKER_RATING_PROMPT.md`**.

```http
POST /api/Reviews/...   # booking completed only
GET /api/Reviews/Worker/{workerId}/Summary
```

---

## 10. Reports (complaints)

Report worker or company — **`FLUTTER_CUSTOMER_REPORTS_PROMPT.md`**.

---

## 11. Notifications

- REST: `/api/Notifications/GetMyNotifications`, `GetUnreadCount`, `MarkAsRead`, etc.
- SignalR: `{baseUrl}/hubs/notifications?access_token={token}`
- Events: `ReceiveNotification`, `BookingStatusChanged`
- **No** notification on booking create for customer; **yes** on status changes

**Full spec:** `FLUTTER_CUSTOMER_NOTIFICATIONS_PROMPT.md`

---

## 12. Profile & account

| Action | API |
|--------|-----|
| Change password | `PUT /api/AppUsers/ChangePassword` |
| Change name/email | `PUT /api/AppUsers/ChangePersonalInfo` |
| Change phone | `PUT /api/AppUsers/ChangePhoneNumber` |
| Wallet | `GET /api/v1/wallet` — **`FLUTTER_CUSTOMER_WALLET_PROMPT.md`** |

---

## 13. Booking status reference

| status | Arabic (suggested) |
|--------|-------------------|
| 0 | قيد الانتظار |
| 1 | مؤكد |
| 2 | في الطريق |
| 3 | مكتمل |
| 4 | ملغي |
| 5 | مرفوض |

Show `rejectionReason` when status = 5.

---

## 14. Feature folder structure

```
lib/
├── core/
│   ├── network/dio_client.dart
│   ├── error/failures.dart
│   ├── pagination/paged_result.dart
│   └── constants/api_constants.dart
├── features/
│   ├── auth/
│   ├── home/
│   ├── companies/
│   ├── workers/
│   ├── bookings/
│   ├── wallet/
│   ├── user_locations/
│   ├── favorites/
│   ├── reviews/
│   ├── reports/
│   ├── notifications/
│   └── profile/
└── injection.dart
```

---

## 15. Error handling

| Code | Action |
|------|--------|
| 401 | Logout |
| 403 | Permission message |
| 409 | Booking conflict |
| 429 | Rate limit |
| 400 | Show `message` or ProblemDetails `detail` |
| 500 | Generic error |

Parse ProblemDetails when present.

---

## 16. UI/UX

- **RTL Arabic** primary
- Currency: **د.ل**
- Loading / empty / error states on every screen
- Debounce 300–500ms on price preview
- Confirm dialogs on cancel booking
- Image URLs: prefix with API host if relative `/Uploads/...`

---

## 17. Related feature prompts (implement in order)

| Order | Topic | File |
|-------|-------|------|
| 0 | **Latest deltas (June 2026)** | `FLUTTER_CUSTOMER_LATEST_UPDATE_PROMPT.md` |
| 1 | API pagination & breaking changes | `FLUTTER_API_UPDATE_PROMPT.md` |
| 2 | Home screen workers | `FLUTTER_HOME_SCREEN_WORKERS_PROMPT.md` |
| 3 | Platform fee & price preview | `FLUTTER_CUSTOMER_PLATFORM_FEE_PROMPT.md` |
| 4 | Create booking / 409 handling | `FLUTTER_CREATE_BOOKING_FIX_PROMPT.md` |
| 5 | Wallet payment | `FLUTTER_CUSTOMER_WALLET_PROMPT.md` |
| 6 | Notifications + SignalR | `FLUTTER_CUSTOMER_NOTIFICATIONS_PROMPT.md` |
| 7 | Worker ratings display | `FLUTTER_CUSTOMER_RATINGS_DISPLAY_PROMPT.md` |
| 8 | Submit review | `FLUTTER_CUSTOMER_WORKER_RATING_PROMPT.md` |
| 9 | Reports | `FLUTTER_CUSTOMER_REPORTS_PROMPT.md` |
| 10 | Forgot password | `FLUTTER_CUSTOMER_FORGOT_PASSWORD_PROMPT.md` |

---

## 18. Testing checklist

- [ ] Login with `userType: "Customer"`
- [ ] Home: available workers change with date
- [ ] Home: top-rated shows `availabilityLabel`
- [ ] Price preview updates on selection change
- [ ] Create booking with location → 201
- [ ] Create booking conflict → 409 message
- [ ] Wallet: top-up cash → pending UI
- [ ] Wallet: pay booking → amount **reserved** (not full capture until arrival/complete)
- [ ] Confirm arrival on OnTheWay → wallet capture
- [ ] Wallet: insufficient balance → top-up CTA
- [ ] Notifications badge + tap → booking
- [ ] Cancel pending booking → wallet refund (balance increases)
- [ ] RTL layout all screens
- [ ] Pagination load-more on long lists

---

## 19. Do NOT

- Parse list responses as root `List` JSON
- Use `GetBookings` for customer list
- Calculate platform fee or wallet fee locally for charging
- Compute worker availability on client
- Expect customer notification on booking create
- Send prices in `CreateBooking` body
- Use `lan` instead of `lng` for locations

---

## PROMPT END
