# Flutter fix prompt — CreateBooking (May 2026)

**Deploy status:** API published to `/var/www/AlbareqApi`, service `albareqapi` restarted. Health: `GET http://102.203.200.55:5545/health` → Healthy.

Copy everything below the line into Cursor / your Flutter AI agent.

---

## PROMPT START

You are fixing a **Flutter** customer app (Clean Architecture: Presentation → Domain → Data) after the **CleaningHouse API** backend fix for `POST /api/Bookings/CreateBooking`.

**Base URL:** `http://102.203.200.55:5545`

**Auth:** `Authorization: Bearer {token}` — **Customer** role required for CreateBooking.

---

## What changed on the server (do NOT change the request body)

The backend previously returned **500** for valid booking payloads when the worker was already booked (EF transaction + retry strategy bug). That is **fixed**.

Your app’s JSON shape is **correct**. Example that works against production:

```json
{
  "companyId": 11,
  "workerId": 10,
  "workTypeId": 9,
  "bookingDate": "2026-05-22T22:00:00.000Z",
  "startDate": "08:35",
  "endDate": "17:30",
  "userLocationId": 5
}
```

**Field rules (unchanged):**

| Field | Type | Notes |
|-------|------|--------|
| `companyId`, `workerId`, `workTypeId` | int | required |
| `bookingDate` | ISO-8601 UTC `DateTime` | calendar day for the booking |
| `startDate`, `endDate` | string | time only, e.g. `"08:35"`, `"17:30"` — **not** full datetimes |
| `userLocationId` | int? | use **OR** `address` (at least one required) |
| `address` | string? | max 500 chars if no saved location |

API copies address from saved location when `userLocationId` is sent.

---

## HTTP responses you MUST handle

| Status | Meaning | Flutter action |
|--------|---------|----------------|
| **201** | Created | Parse `BookingDTO` body, navigate to success / booking detail |
| **400** | Validation / business rule | Show `detail` or model-state message (Arabic possible) |
| **401** | Unauthorized | Refresh login |
| **409** | **Worker already booked** for that date + time window | **Not a server crash** — show friendly message, refresh availability |
| **429** | Rate limited | Show “try again later” |
| **500** | Real server error | Generic error; log for support |

### 409 Conflict (critical fix)

When the worker is double-booked, the API returns **409** with **ProblemDetails** JSON:

```json
{
  "title": "Conflict",
  "status": 409,
  "detail": "العاملة محجوزة بالفعل في هذا التوقيت.",
  "instance": "/api/Bookings/CreateBooking"
}
```

**Do NOT** map 409 to a generic `ServerFailure` or “حدث خطأ في الخادم”. Treat it as **`BookingConflictFailure`** (or similar domain failure) with message from `detail`.

### 201 Created body (`BookingDTO`)

```json
{
  "id": 1,
  "userId": 11,
  "userName": "...",
  "companyId": 11,
  "companyName": "...",
  "workerId": 10,
  "workerName": "...",
  "workTypeId": 9,
  "workTypeName": "...",
  "bookingDate": "2026-05-22T22:00:00.000Z",
  "startDate": "08:35",
  "endDate": "17:30",
  "address": "...",
  "userLocationId": 5,
  "locationName": "...",
  "lat": 24.7,
  "lng": 46.6,
  "status": 0,
  "rejectionReason": null,
  "createdAt": "..."
}
```

`status`: 0=Pending, 1=Approved, 2=On the way, 3=Completed, 4=Canceled, 5=Rejected.

---

## Required Flutter changes (Clean Architecture)

### 1. Data layer — `booking_remote_datasource` (or equivalent)

On `POST /api/Bookings/CreateBooking`:

```dart
// Pseudocode — adapt to your Dio wrapper
try {
  final response = await _dio.post('/api/Bookings/CreateBooking', data: body);
  return BookingModel.fromJson(response.data);
} on DioException catch (e) {
  final status = e.response?.statusCode;
  if (status == 409) {
    final detail = _parseProblemDetail(e.response?.data);
    throw BookingConflictException(detail ?? 'العاملة محجوزة بالفعل في هذا التوقيت.');
  }
  if (status == 400) {
    throw ValidationException(_parseErrorMessage(e.response?.data));
  }
  rethrow;
}
```

Helper to parse ProblemDetails:

```dart
String? _parseProblemDetail(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['detail'] as String? ?? data['title'] as String?;
  }
  return null;
}
```

Ensure `validateStatus` does not swallow 409 — you need the response body. Either:

- keep default (throws on 4xx/5xx) and catch `DioException`, **or**
- use `validateStatus: (s) => s != null && s < 500` and branch on `statusCode`.

### 2. Domain layer

- Add failure type: `BookingConflictFailure(String message)` extending your `Failure` base.
- `CreateBookingUseCase` maps `BookingConflictException` → `Left(BookingConflictFailure(...))`.

### 3. Presentation layer

In the booking cubit/bloc:

- **Success (201):** emit success with created booking.
- **Conflict (409):** emit state with user-visible Arabic/English message; **do not** show “500 server error”.
- Optional UX: on 409, reload `GET /api/Workers/Available?date={yyyy-MM-dd}&page=1&pageSize=20` for the same date so the list excludes busy workers.

### 4. Pre-submit UX (recommended)

Before calling CreateBooking:

- User picks date → load available workers for that date (paginated `PagedResult`).
- If user changes time after picking worker, consider re-checking or showing that slot may no longer be available.
- On 409, suggest: choose another time, another worker, or another date.

---

## Related endpoints (unchanged but required for flow)

| Endpoint | Role | Notes |
|----------|------|--------|
| `GET /api/UserLocations/GetMyLocations?page=1&pageSize=20` | Customer | Pick `userLocationId` |
| `GET /api/Workers/Available?date=2026-05-22&page=1&pageSize=20` | Customer | Paginated — parse `items`, not root array |
| `GET /api/Bookings/User/{userId}?page=1&pageSize=20` | Customer | List my bookings — **not** `GetBookings` |

List responses use:

```json
{ "items": [], "page": 1, "pageSize": 20, "totalCount": 0, "totalPages": 0, "hasNextPage": false, "hasPreviousPage": false }
```

---

## Debugging checklist

- [ ] CreateBooking sends `userLocationId` **or** `address` (your log shows `userLocationId: 5` — good).
- [ ] `startDate` / `endDate` are `"HH:mm"` strings, not DateTime objects serialized wrongly.
- [ ] `bookingDate` is UTC ISO string from the selected calendar day.
- [ ] Dio catches **409** and surfaces `detail` to UI.
- [ ] 409 is **not** logged as “fix the server”.
- [ ] Test: duplicate booking same worker/date/times → UI shows conflict message, not 500.

---

## Test with curl (optional)

```bash
curl -sS -X POST 'http://102.203.200.55:5545/api/Bookings/CreateBooking' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_CUSTOMER_JWT' \
  -d '{"companyId":11,"workerId":10,"workTypeId":9,"bookingDate":"2026-05-22T22:00:00.000Z","startDate":"08:35","endDate":"17:30","userLocationId":5}'
```

- **409** = slot taken (expected for duplicate test).
- **201** = success with booking JSON body.

---

## PROMPT END

For full API migration (pagination, locations, profile), also use `FLUTTER_API_UPDATE_PROMPT.md` in the same repo.
