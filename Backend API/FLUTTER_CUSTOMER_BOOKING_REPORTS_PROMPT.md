# Flutter Customer App — Booking Reports Feature (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

Implement **Booking Reports** (بلاغ على حجز) in the **Bareq Customer** Flutter app using **Clean Architecture** (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Auth:** `Authorization: Bearer {customerToken}` on all endpoints below.

This is **separate** from worker/company reports (`/api/Reports/*`). Booking reports let a customer complain about a **specific booking** (delay, rejection reason, company behavior, etc.).

---

## User flows

### Flow A — Report from booking detail

1. Customer opens **My Booking** detail page
2. If booking status allows reporting → show **"تقديم بلاغ"** button
3. Customer enters **reason** (required) + optional **description**
4. Submit → success snackbar → optional navigate to **"بلاغات الحجوزات"**

### Flow B — My booking reports list

1. Profile / bookings section → **"بلاغات الحجوزات"**
2. Paginated list of own booking reports with status badges
3. Tap row → report detail (read-only)

### Flow C — Reports for one booking

1. From booking detail → **"بلاغات هذا الحجز"** (if any exist or after submitting)
2. Shows reports linked to that `bookingId` only

### Flow D — Notification tap

When customer receives notification type **BookingReportStatusUpdated** (`notificationType: 22`):

- Message: **"تم تحديث حالة البلاغ الخاص بالحجز."**
- `relatedEntityId` = **booking report id** (not booking id)
- Tap → open **Booking Report Detail** page (load from MyReports list cache or refetch MyReports and find by id)

---

## When to show "تقديم بلاغ"

Show the report action only when `booking.status` is one of:

| Status | Value | Can report? |
|--------|-------|-------------|
| Pending | 0 | Yes |
| Approved | 1 | Yes |
| OnTheWay | 2 | Yes |
| Rejected | 5 | Yes |
| Completed | 3 | **No** |
| Canceled | 4 | **No** |

**Also hide** the button if the customer already has an **active** report on this booking (`status` 0 Open or 1 InReview).  
Check via `GET /api/BookingReports/Booking/{bookingId}` — if any item has `status` 0 or 1, disable/hide create.

---

## API endpoints (Customer JWT only)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/BookingReports` | Create booking report |
| GET | `/api/BookingReports/MyReports?page=1&pageSize=20` | All own booking reports |
| GET | `/api/BookingReports/Booking/{bookingId}?page=1&pageSize=20` | Reports for one owned booking |

> Customer **cannot** call admin endpoints (`GET /api/BookingReports`, `GET /api/BookingReports/{id}`, `PATCH .../Status`).

---

## Create booking report

```http
POST /api/BookingReports
Authorization: Bearer {customerToken}
Content-Type: application/json
```

```json
{
  "bookingId": 80,
  "reason": "رفض غير مبرر",
  "description": "سبب الرفض غير واضح"
}
```

| Field | Rules |
|-------|--------|
| `bookingId` | Required — must be customer's own booking |
| `reason` | Required, max **200** chars |
| `description` | Optional, max **1000** chars |

**Success (201):** `BookingReportResponse`

```json
{
  "id": 1,
  "bookingId": 80,
  "customerId": 23,
  "customerName": "Mohamed benhamed",
  "companyId": 1013,
  "companyName": "البريق الامع",
  "workerId": 13,
  "workerName": "عبير الاسمر",
  "reason": "رفض غير مبرر",
  "description": "سبب الرفض غير واضح",
  "status": 0,
  "statusName": "مفتوح",
  "adminResolutionNotes": null,
  "resolvedByAdminId": null,
  "resolvedByAdminName": null,
  "resolvedAt": null,
  "createdAt": "2026-06-06T18:17:27.1780059",
  "updatedAt": null,
  "bookingStatus": 5,
  "bookingStatusName": "مرفوض"
}
```

**Errors (400/404):** `{ "message": "..." }` — Arabic, e.g.:

- `"الحجز غير موجود أو لا يخصك."`
- `"لا يمكن تقديم بلاغ على حجز مكتمل أو ملغي."`
- `"يوجد بلاغ مفتوح بالفعل على هذا الحجز."`
- `"سبب البلاغ مطلوب."` / validation from ModelState

---

## My booking reports

```http
GET /api/BookingReports/MyReports?page=1&pageSize=20
Authorization: Bearer {customerToken}
```

**Response:** `PagedResult<BookingReportResponse>`

```json
{
  "items": [ { /* BookingReportResponse */ } ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 1,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

---

## Reports for one booking

```http
GET /api/BookingReports/Booking/80?page=1&pageSize=20
Authorization: Bearer {customerToken}
```

Same `PagedResult` shape. **404** if booking does not belong to customer.

---

## Status enums (client)

### Booking report status

```dart
enum BookingReportStatus {
  open,       // 0 — مفتوح
  inReview,   // 1 — قيد المراجعة
  resolved,   // 2 — تم الحل
  rejected,   // 3 — مرفوض
}

// Prefer API statusName for display; use enum for badge colors.
```

| Value | statusName (API) | Badge color hint |
|-------|------------------|------------------|
| 0 | مفتوح | orange |
| 1 | قيد المراجعة | blue |
| 2 | تم الحل | green |
| 3 | مرفوض | red |

### Booking status (context on report card)

Use `bookingStatus` / `bookingStatusName` from response — do not re-fetch booking for list tiles.

---

## Feature folder structure

```
lib/features/booking_reports/
├── data/
│   ├── models/
│   │   └── booking_report_model.dart
│   ├── datasources/
│   │   └── booking_report_remote_datasource.dart
│   └── repositories/
│       └── booking_report_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── booking_report.dart
│   ├── repositories/
│   │   └── booking_report_repository.dart
│   └── usecases/
│       ├── create_booking_report_usecase.dart
│       ├── get_my_booking_reports_usecase.dart
│       └── get_booking_reports_by_booking_usecase.dart
└── presentation/
    ├── state/
    │   ├── create_booking_report_cubit.dart
    │   ├── my_booking_reports_cubit.dart
    │   └── booking_reports_by_booking_cubit.dart
    ├── pages/
    │   ├── create_booking_report_page.dart
    │   ├── my_booking_reports_page.dart
    │   ├── booking_reports_by_booking_page.dart
    │   └── booking_report_detail_page.dart
    └── widgets/
        ├── booking_report_status_badge.dart
        └── booking_report_list_tile.dart
```

---

## Domain layer

```dart
class BookingReport {
  final int id;
  final int bookingId;
  final int customerId;
  final String customerName;
  final int companyId;
  final String companyName;
  final int? workerId;
  final String? workerName;
  final String reason;
  final String? description;
  final int status;
  final String statusName;
  final String? adminResolutionNotes;
  final int? resolvedByAdminId;
  final String? resolvedByAdminName;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int bookingStatus;
  final String bookingStatusName;

  bool get isActive => status == 0 || status == 1;
}

abstract class BookingReportRepository {
  Future<Either<Failure, BookingReport>> createBookingReport({
    required int bookingId,
    required String reason,
    String? description,
  });

  Future<Either<Failure, PagedResult<BookingReport>>> getMyBookingReports({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, PagedResult<BookingReport>>> getReportsByBookingId({
    required int bookingId,
    int page = 1,
    int pageSize = 20,
  });
}
```

---

## Data layer

```dart
// booking_report_model.dart — fromJson/toJson, toEntity()

// booking_report_remote_datasource.dart
class BookingReportRemoteDataSource {
  final ApiClient _client;

  Future<BookingReportModel> createBookingReport({
    required int bookingId,
    required String reason,
    String? description,
  }) async {
    final response = await _client.post(
      '/api/BookingReports',
      data: {
        'bookingId': bookingId,
        'reason': reason.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
    return BookingReportModel.fromJson(response.data);
  }

  Future<PagedResult<BookingReportModel>> getMyBookingReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/BookingReports/MyReports',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(
      response.data,
      (json) => BookingReportModel.fromJson(json),
    );
  }

  Future<PagedResult<BookingReportModel>> getReportsByBookingId({
    required int bookingId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/BookingReports/Booking/$bookingId',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(
      response.data,
      (json) => BookingReportModel.fromJson(json),
    );
  }
}
```

**Error mapping:** parse `{ "message": "..." }` from 400/404 into `ServerFailure(message)`.

---

## Presentation — Create booking report page

### Navigation params

```dart
CreateBookingReportPage({
  required int bookingId,
  required String bookingLabel,   // e.g. "#80 — البريق الامع"
  required int bookingStatus,     // to validate client-side before API
});
```

### Form

| Label (AR) | Field |
|------------|-------|
| الحجز | Read-only booking label |
| سبب البلاغ | Single line or short multiline, **required**, max 200 |
| تفاصيل إضافية | Optional multiline, max 1000 |
| | Counters: `{reason.length}/200`, `{description.length}/1000` |

**Client validation before submit:**

- `reason` not empty after trim
- `reason.length <= 200`
- `description.length <= 1000` if provided
- `bookingStatus` not in `[3, 4]` (Completed, Canceled)

**Submit:** **"إرسال البلاغ"**

**On success:** Snackbar **"تم إرسال بلاغك بنجاح. سيتم مراجعته من قبل الإدارة."** → pop or navigate to report detail.

**On error:** Show API `message` in snackbar/dialog.

---

## Presentation — Booking detail integration

On **Booking Detail** page (`/bookings/{id}`):

```dart
bool canReportBooking(int status) =>
    status == 0 || status == 1 || status == 2 || status == 5;

// Load reports for this booking (lightweight) to check active report
// Use BookingReportsByBookingCubit or one-shot use case on page init

if (canReportBooking(booking.status) && !hasActiveReport) {
  ElevatedButton.icon(
    icon: Icon(Icons.report_problem_outlined),
    label: Text('تقديم بلاغ'),
    onPressed: () => context.push('/booking-reports/create', extra: {
      'bookingId': booking.id,
      'bookingLabel': '#${booking.id} — ${booking.companyName}',
      'bookingStatus': booking.status,
    }),
  );
}

// Optional secondary action
TextButton(
  onPressed: () => context.push('/booking-reports/booking/${booking.id}'),
  child: Text('بلاغات هذا الحجز'),
);
```

---

## Presentation — My booking reports page

- Route: `/booking-reports/my`
- Entry: Profile → **"بلاغات الحجوزات"** (distinct from worker/company **"بلاغاتي"** under `/api/Reports`)
- Paginated list (`hasNextPage` / infinite scroll)
- Each tile:
  - Booking `#bookingId`
  - Company name, worker name
  - `reason` (1 line)
  - `statusName` badge
  - `createdAt` formatted
- Tap → `BookingReportDetailPage`
- Pull-to-refresh

---

## Presentation — Report detail page (read-only)

Show:

- Booking `#bookingId` + `bookingStatusName`
- Company + worker names
- Reason + full description
- Status badge (`statusName`)
- Created date
- If `status` is 2 or 3 and `adminResolutionNotes` is not null → section **"ملاحظات الإدارة"** with notes + `resolvedAt`

**Do NOT** show admin name to customer unless product asks — optional footer "تم الحل بواسطة الإدارة".

---

## Cubit states

```dart
sealed class CreateBookingReportState {}
class CreateBookingReportInitial extends CreateBookingReportState {}
class CreateBookingReportLoading extends CreateBookingReportState {}
class CreateBookingReportSuccess extends CreateBookingReportState {
  final BookingReport report;
}
class CreateBookingReportError extends CreateBookingReportState {
  final String message;
}

sealed class MyBookingReportsState {}
class MyBookingReportsLoading extends MyBookingReportsState {}
class MyBookingReportsLoaded extends MyBookingReportsState {
  final List<BookingReport> reports;
  final bool hasNextPage;
  final int page;
}
class MyBookingReportsError extends MyBookingReportsState {
  final String message;
}
```

---

## Notifications integration

Add to existing notifications handler:

```dart
// notificationType == 22 → BookingReportStatusUpdated
// relatedEntityId → booking REPORT id

void onNotificationTap(NotificationDto n) {
  if (n.notificationType == 22 && n.relatedEntityId != null) {
    context.push('/booking-reports/detail/${n.relatedEntityId}');
    return;
  }
  // existing booking status handlers use relatedEntityId as bookingId (types 10-16)
}
```

**Do not** open booking detail for type 22 — open **booking report detail**.

---

## Dependency injection

Register in `core/di`:

- `BookingReportRemoteDataSource`
- `BookingReportRepositoryImpl` → `BookingReportRepository`
- `CreateBookingReportUseCase`
- `GetMyBookingReportsUseCase`
- `GetBookingReportsByBookingUseCase`
- `CreateBookingReportCubit` (factory)
- `MyBookingReportsCubit` (factory)
- `BookingReportsByBookingCubit` (factory)

---

## Routes (go_router example)

```dart
GoRoute(
  path: '/booking-reports/create',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return CreateBookingReportPage(
      bookingId: extra['bookingId'] as int,
      bookingLabel: extra['bookingLabel'] as String,
      bookingStatus: extra['bookingStatus'] as int,
    );
  },
),
GoRoute(
  path: '/booking-reports/my',
  builder: (_, __) => const MyBookingReportsPage(),
),
GoRoute(
  path: '/booking-reports/booking/:bookingId',
  builder: (context, state) => BookingReportsByBookingPage(
    bookingId: int.parse(state.pathParameters['bookingId']!),
  ),
),
GoRoute(
  path: '/booking-reports/detail/:id',
  builder: (context, state) => BookingReportDetailPage(
    reportId: int.parse(state.pathParameters['id']!),
  ),
),
```

Detail page can load report from cubit cache or refetch `MyReports` and find by id (customer has no `GET by id` endpoint).

---

## Testing checklist

- [ ] Report button visible for Pending / Approved / OnTheWay / Rejected bookings
- [ ] Report button hidden for Completed / Canceled
- [ ] Report button hidden when active report exists (Open/InReview)
- [ ] Create report → 201 success
- [ ] Duplicate active report → 400 Arabic message
- [ ] Reason required; max 200 enforced client-side
- [ ] Description optional; max 1000 enforced
- [ ] My reports lists only own booking reports
- [ ] Reports by booking returns only that booking's reports
- [ ] Status badge uses `statusName` from API
- [ ] Resolved report shows `adminResolutionNotes` when present
- [ ] Notification type 22 opens report detail (not booking detail)
- [ ] 401 redirects to login
- [ ] Pagination on MyReports works

---

## Do NOT

- Call `/api/Reports/*` for booking complaints — use `/api/BookingReports`
- Call API from widgets directly
- Allow report on Completed/Canceled bookings
- Use admin endpoints from customer app
- Parse paged response as root `List`
- Change booking status from the client when submitting a report

---

## Related docs

| Topic | File |
|-------|------|
| Worker/company reports | `FLUTTER_CUSTOMER_REPORTS_PROMPT.md` |
| Booking detail / list | `FLUTTER_CUSTOMER_APP_IMPLEMENTATION_PROMPT.md` |
| Notifications | `FLUTTER_CUSTOMER_NOTIFICATIONS_PROMPT.md` |
| Latest API updates | `FLUTTER_CUSTOMER_LATEST_UPDATE_PROMPT.md` |

---

## PROMPT END
