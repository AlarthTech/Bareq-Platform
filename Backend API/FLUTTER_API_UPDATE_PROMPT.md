# Flutter app update prompt — CleaningHouse API (May 2026)

Copy everything below the line into Cursor / your Flutter AI agent.

---

## PROMPT START

You are updating a **Flutter** app (Clean Architecture: Presentation → Domain → Data) to match the **production CleaningHouse API** deployed at:

**Base URL:** `http://102.203.200.55:5545`

**Swagger (testing):** `http://102.203.200.55:5545/swagger`

**Auth:** `Authorization: Bearer {token}` on protected routes.

**Login:** `POST /api/AppUsers/Login` — body: `{ "username": "email-or-phone", "password": "...", "userType": "Customer" | "Company" | "Admin" }`  
Response: `{ "success", "message", "token", "user" }` — store `token` and user id from JWT / `user` object.

---

## 1. BREAKING CHANGE — All list endpoints use pagination

**Do NOT** parse list responses as `List<T>` from the root JSON.

**New wrapper** — every paginated list returns:

```json
{
  "items": [ /* T[] */ ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 42,
  "totalPages": 3,
  "hasNextPage": true,
  "hasPreviousPage": false
}
```

### Data layer (required)

Create a generic model:

```dart
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  // fromJson: parse items with itemFromJson callback
}
```

### Query parameters (all list GETs)

- `page` — default `1`
- `pageSize` — default `20`, **max `50`**

Example:  
`GET /api/Workers/Available?page=1&pageSize=20&date=2026-05-22`

### UI / state

- Use **infinite scroll** or **load more** when `hasNextPage == true` (increment `page`).
- Replace any `response.data as List` with `PagedResult.fromJson(...).items`.

### Paginated endpoints (update ALL repository methods that call these)

| Endpoint | Notes |
|----------|--------|
| `GET /api/Bookings/User/{userId}` | Customer bookings — **use this instead of GetBookings** |
| `GET /api/Bookings/Company/{companyId}` | Company bookings |
| `GET /api/Bookings/GetBookings` | **Admin only** — was public before |
| `GET /api/Workers/Available?date=yyyy-MM-dd` | Customer worker search by date |
| `GET /api/Workers/GetActiveWorkers` | |
| `GET /api/Workers/GetAvailableWorkers` | filters + pagination |
| `GET /api/Workers/Company/{companyId}` | **requires JWT** (not anonymous) |
| `GET /api/Workers/GetWorkers` | **Admin only** |
| `GET /api/Companies/GetActiveCompanies` | |
| `GET /api/Companies/GetisVerifiedCompanies` | |
| `GET /api/Reviews/Worker/{workerId}` | |
| `GET /api/Favorites/User/{userId}` | |
| `GET /api/WorkTypes/GetWorkTypesByCompany/{companyId}` | |
| `GET /api/UserLocations/GetMyLocations` | |
| Others in Swagger tagged as list | Check Swagger |

**Single-item GETs** (by id) are unchanged — still return one object, not `PagedResult`.

---

## 2. Auth / endpoint access changes

| Old assumption | New rule |
|----------------|----------|
| `GET /api/Bookings/GetBookings` without login | **Forbidden** — Admin JWT only |
| `GET /api/Workers/GetWorkers` public | **Admin only** |
| `GET /api/Workers/Company/{id}` public | **JWT required** — company owner or admin |

### Customer app

- Bookings list: `GET /api/Bookings/User/{currentUserId}?page=1&pageSize=20`
- Workers for date: `GET /api/Workers/Available?page=1&pageSize=20&date=2026-05-22`
- Create booking: `POST /api/Bookings/CreateBooking` — **Customer** role JWT

### Company app

- Bookings list: `GET /api/Bookings/Company/{companyId}?page=1&pageSize=20`
- Company workers: `GET /api/Workers/Company/{companyId}?page=1&pageSize=20` with company JWT

---

## 3. Booking model — location fields

`BookingDTO` now includes:

```json
{
  "id": 1,
  "userId": 10,
  "userName": "...",
  "companyId": 1,
  "companyName": "...",
  "workerId": 2,
  "workerName": "...",
  "workTypeId": 3,
  "workTypeName": "...",
  "bookingDate": "2026-05-20T10:00:00Z",
  "startDate": "09:00",
  "endDate": "12:00",
  "address": "Home",
  "userLocationId": 5,
  "locationName": "Home",
  "lat": 32.8872,
  "lng": 13.1913,
  "status": 0,
  "rejectionReason": null,
  "createdAt": "..."
}
```

### Create booking

`POST /api/Bookings/CreateBooking`

**Option A — saved location (preferred):**

```json
{
  "companyId": 1,
  "workerId": 2,
  "workTypeId": 3,
  "bookingDate": "2026-05-20T10:00:00Z",
  "startDate": "09:00",
  "endDate": "12:00",
  "userLocationId": 5
}
```

**Option B — manual address:**

```json
{
  "...": "...",
  "address": "Street text"
}
```

Must send **`userLocationId` OR `address`** (at least one).

### HTTP 409 Conflict

If worker is already booked for that date/slot:

- Status: **409**
- Body: ProblemDetails — `detail` may be Arabic: `العاملة محجوزة بالفعل في هذا التوقيت.`

Show user-friendly message and refresh availability.

### Booking status enum (unchanged values)

| status | Meaning |
|--------|---------|
| 0 | Pending |
| 1 | Approved |
| 2 | On the way |
| 3 | Completed |
| 4 | Canceled |
| 5 | Rejected — show `rejectionReason` |

Company updates status: `PATCH /api/Bookings/UpdateStatusBooking/{id}`  
Body: `{ "status": 5, "rejectionReason": "required when status=5" }`

---

## 4. User saved locations (new feature)

Base: `/api/UserLocations` — **JWT required**

| Method | Path | Body |
|--------|------|------|
| GET | `/GetMyLocations?page=1&pageSize=20` | — |
| GET | `/GetUserLocationById/{id}` | — |
| POST | `/CreateUserLocation` | `{ "locationName", "lat", "lng" }` — all required |
| PUT | `/UpdateUserLocation/{id}` | optional `locationName`, `lat`, `lng` |
| DELETE | `/DeleteUserLocation/{id}` | — |

**Note:** API uses **`lng`** (longitude), not `lan`.

### Customer flow

1. Screen: manage locations (map picker → create).
2. Booking flow: pick saved location → pass `userLocationId` to `CreateBooking`.
3. Booking detail: show map if `lat`/`lng` present.

---

## 5. Account settings (new APIs)

Base: `/api/AppUsers` — **JWT required** (user from token)

| Method | Path | Body | Response |
|--------|------|------|----------|
| PUT | `/ChangePassword` | `{ "currentPassword", "newPassword" }` min 6 | `{ "message" }` |
| PUT | `/ChangePersonalInfo` | `{ "fullName", "email" }` | `AppUserDTO` |
| PUT | `/ChangePhoneNumber` | `{ "phone" }` | `AppUserDTO` |

Arabic error strings possible in **400** body (plain text or problem+json).

---

## 6. Error handling (Dio / API client)

### ProblemDetails (500, some 400/409)

```json
{
  "title": "Internal Server Error",
  "status": 500,
  "detail": "An unexpected error occurred.",
  "instance": "/api/Workers/Available"
}
```

Parse `detail` for user message when present.

### Status codes to handle

| Code | Action |
|------|--------|
| 401 | Redirect to login |
| 403 | Show "not allowed" |
| 409 | Booking conflict — worker taken |
| 429 | Rate limit — show "try again later" |
| 500 | Generic error + optional `detail` |

### Login errors

Login still returns `LoginResponseDTO` with `success: false` and `message` (not always ProblemDetails).

---

## 7. Dio / Retrofit checklist

- [ ] Add `PagedResult<T>` + code gen or manual `fromJson`
- [ ] Update every list API method return type to `Future<PagedResult<WorkerDto>>` etc.
- [ ] Add `@Query('page')` and `@Query('pageSize')` to list calls
- [ ] Fix `Workers/Available` — ensure `date` format `yyyy-MM-dd` query param
- [ ] Remove calls to anonymous `GetBookings` for customers
- [ ] Parse booking `items` + map `lat`/`lng`/`locationName`
- [ ] Create booking: send `userLocationId` or `address`; handle 409
- [ ] Add UserLocations feature (data + domain + presentation)
- [ ] Add profile: change password / email / name / phone
- [ ] Repository: never expect root JSON array for lists

---

## 8. Clean Architecture mapping

```
features/
  bookings/
    data/models/booking_dto.dart       // + userLocationId, locationName, lat, lng
    data/models/paged_result.dart      // generic
    data/datasources/booking_remote.dart
    domain/entities/booking.dart
    presentation/...                   // pagination state, 409 handling
  workers/
    ...                                // PagedResult for Available
  user_locations/                      // NEW feature
  profile/                             // ChangePassword, PersonalInfo, Phone
  auth/
    ...                                // Login unchanged
```

---

## 9. Quick test URLs (curl)

```bash
# Health
curl http://102.203.200.55:5545/health

# Workers available (paginated)
curl "http://102.203.200.55:5545/api/Workers/Available?page=1&pageSize=20&date=2026-05-22"

# With auth
curl -H "Authorization: Bearer TOKEN" \
  "http://102.203.200.55:5545/api/Bookings/User/11?page=1&pageSize=20"
```

---

## 10. Do NOT change

- Login request/response shape (`LoginResponseDTO`)
- Single GET by id responses (worker, company, booking by id) — still single object
- JWT claim role names: `Customer`, `Company`, `Admin`
- `userType` on login: `"Customer"`, `"Company"`, `"Admin"`

Implement incrementally: **pagination first** (fixes most Dio parse errors), then **Workers/Available**, then **locations + booking**, then **profile APIs**.

## PROMPT END
