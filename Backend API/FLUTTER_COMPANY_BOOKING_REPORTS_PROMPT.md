# Flutter Company App — Booking Reports Feature (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Company** app agent.

---

## PROMPT START

Implement **Booking Reports** (بلاغات الحجوزات) in the **Bareq Company** Flutter app using **Clean Architecture** (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Auth:** `Authorization: Bearer {companyToken}` — login with `"userType": "Company"`

Company owners can **view and resolve** booking reports filed by customers against bookings for **their company**. They **cannot** create reports (customer-only).

This is **separate** from worker/company profile reports (`/api/Reports/*`).

---

## User flows

### Flow A — Reports inbox (main)

1. Company owner opens **بلاغات الحجوزات** from drawer / operations menu
2. Paginated list of reports for their company bookings
3. Filter by status (مفتوح / قيد المراجعة / تم الحل / مرفوض)
4. Tap row → report detail

### Flow B — Report detail + resolve

1. Show customer complaint, booking context, worker, reason, description
2. Company owner updates status:
   - **بدء المراجعة** → InReview (1)
   - **تم الحل** → Resolved (2) + notes required
   - **رفض البلاغ** → Rejected (3) + notes required
3. On Resolved/Rejected → customer receives notification automatically

### Flow C — From booking detail

1. On company **booking detail** page → section **"بلاغات الحجز"**
2. `GET /api/BookingReports?bookingId={id}` (scoped to company automatically)
3. Tap report → detail + resolve actions

### Flow D — Notification tap

When company owner receives notification:

- `notificationType: 23` (BookingReportSubmittedForCompany)
- Message AR: **"تم تقديم بلاغ على أحد حجوزات الشركة."**
- `relatedEntityId` = **booking report id**
- Tap → `/company/booking-reports/{id}`

---

## API endpoints (Company JWT only)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/BookingReports` | List reports for **owned company** bookings |
| GET | `/api/BookingReports/{id}` | Report detail (own company only) |
| PATCH | `/api/BookingReports/{id}/Status` | Update status + resolution notes |

> Company **cannot** call:
> - `POST /api/BookingReports` (customer create)
> - `GET /api/BookingReports/MyReports`
> - `GET /api/BookingReports/Booking/{bookingId}` (customer-only route — use list filter `bookingId` instead)

### Login

```http
POST /api/AppUsers/Login
Content-Type: application/json
```

```json
{
  "username": "company@email.com",
  "password": "...",
  "userType": "Company"
}
```

---

## List company booking reports

```http
GET /api/BookingReports?status=0&bookingId=80&page=1&pageSize=20
Authorization: Bearer {companyToken}
```

### Query parameters (all optional)

| Param | Type | Notes |
|-------|------|-------|
| `status` | int | 0 Open · 1 InReview · 2 Resolved · 3 Rejected |
| `bookingId` | int | Filter by booking |
| `customerId` | int | Filter by customer |
| `companyId` | int | Must be **your** company id or **403** |
| `workerId` | int | Filter by worker |
| `fromDate` | date | `YYYY-MM-DD` |
| `toDate` | date | `YYYY-MM-DD` |
| `page` | int | Default 1 |
| `pageSize` | int | Default 20, max 50 |

**Server automatically restricts** results to companies where `OwnerUserId` = logged-in user. No need to send `companyId` unless filtering within your own company.

**Response:** `PagedResult<BookingReportResponse>`

```json
{
  "items": [
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
  ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 1,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

---

## Report detail

```http
GET /api/BookingReports/1
Authorization: Bearer {companyToken}
```

**403:** `{ "message": "لا تملك صلاحية عرض هذا البلاغ." }` — report belongs to another company  
**404:** `{ "message": "البلاغ غير موجود." }`

---

## Update status (resolve / reject / in review)

```http
PATCH /api/BookingReports/1/Status
Authorization: Bearer {companyToken}
Content-Type: application/json
```

**Start review (notes optional):**

```json
{ "status": 1 }
```

**Resolve (notes required):**

```json
{
  "status": 2,
  "adminResolutionNotes": "تم التواصل مع العميل وحل المشكلة"
}
```

**Reject report (notes required):**

```json
{
  "status": 3,
  "adminResolutionNotes": "البلاغ غير مبرر بعد المراجعة"
}
```

| Field | Rules |
|-------|--------|
| `status` | **1** InReview · **2** Resolved · **3** Rejected (not 0) |
| `adminResolutionNotes` | **Required** when status is 2 or 3; max **1000** chars |

**Success (200):** updated `BookingReportResponse`  
- `resolvedByAdminId` / `resolvedByAdminName` = **company owner user** who resolved  
- Customer notified when status is 2 or 3

**Errors:**

- `"ملاحظات الإدارة مطلوبة عند حل البلاغ أو رفضه."`
- `"لا تملك صلاحية تحديث هذا البلاغ."` (403)
- `"البلاغ في هذه الحالة بالفعل."`

---

## Status enums

### Report status

| Value | statusName | Badge |
|-------|------------|-------|
| 0 | مفتوح | orange |
| 1 | قيد المراجعة | blue |
| 2 | تم الحل | green |
| 3 | مرفوض | red |

### Booking status (context)

Use `bookingStatus` / `bookingStatusName` from API on each report.

| Value | bookingStatusName |
|-------|-----------------|
| 0 | قيد الانتظار |
| 1 | مؤكد |
| 2 | في الطريق |
| 3 | مكتمل |
| 4 | ملغي |
| 5 | مرفوض |

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
│       ├── get_company_booking_reports_usecase.dart
│       ├── get_booking_report_by_id_usecase.dart
│       └── update_booking_report_status_usecase.dart
└── presentation/
    ├── state/
    │   ├── company_booking_reports_cubit.dart
    │   ├── booking_report_detail_cubit.dart
    │   └── update_booking_report_status_cubit.dart
    ├── pages/
    │   ├── company_booking_reports_page.dart
    │   └── booking_report_detail_page.dart
    └── widgets/
        ├── booking_report_status_badge.dart
        ├── booking_report_list_tile.dart
        └── update_booking_report_status_sheet.dart
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

  bool get isOpen => status == 0;
  bool get isActive => status == 0 || status == 1;
  bool get isTerminal => status == 2 || status == 3;
}

class BookingReportFilters {
  final int? status;
  final int? bookingId;
  final int? customerId;
  final int? workerId;
  final DateTime? fromDate;
  final DateTime? toDate;
}

abstract class BookingReportRepository {
  Future<Either<Failure, PagedResult<BookingReport>>> getCompanyBookingReports({
    BookingReportFilters? filters,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, BookingReport>> getBookingReportById(int id);

  Future<Either<Failure, BookingReport>> updateBookingReportStatus({
    required int id,
    required int status,
    String? adminResolutionNotes,
  });
}
```

---

## Data layer

```dart
class BookingReportRemoteDataSource {
  final ApiClient _client;

  Future<PagedResult<BookingReportModel>> getCompanyBookingReports({
    BookingReportFilters? filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/api/BookingReports',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (filters?.status != null) 'status': filters!.status,
        if (filters?.bookingId != null) 'bookingId': filters!.bookingId,
        if (filters?.customerId != null) 'customerId': filters!.customerId,
        if (filters?.workerId != null) 'workerId': filters!.workerId,
        if (filters?.fromDate != null)
          'fromDate': filters!.fromDate!.toIso8601String().split('T').first,
        if (filters?.toDate != null)
          'toDate': filters!.toDate!.toIso8601String().split('T').first,
      },
    );
    return PagedResult.fromJson(
      response.data,
      (json) => BookingReportModel.fromJson(json),
    );
  }

  Future<BookingReportModel> getBookingReportById(int id) async {
    final response = await _client.get('/api/BookingReports/$id');
    return BookingReportModel.fromJson(response.data);
  }

  Future<BookingReportModel> updateBookingReportStatus({
    required int id,
    required int status,
    String? adminResolutionNotes,
  }) async {
    final response = await _client.patch(
      '/api/BookingReports/$id/Status',
      data: {
        'status': status,
        if (adminResolutionNotes != null && adminResolutionNotes.trim().isNotEmpty)
          'adminResolutionNotes': adminResolutionNotes.trim(),
      },
    );
    return BookingReportModel.fromJson(response.data);
  }
}
```

Map API errors: `{ "message": "..." }` → `ServerFailure`.

---

## Presentation — Reports list page

**Route:** `/company/booking-reports`

### Drawer / menu entry

```dart
ListTile(
  leading: Icon(Icons.report_problem_outlined),
  title: Text('بلاغات الحجوزات'),
  onTap: () => context.push('/company/booking-reports'),
)
```

Optional badge: count of Open reports (`GET ?status=0&page=1&pageSize=1` → `totalCount`).

### Filter chips / dropdown

- الكل
- مفتوح (0)
- قيد المراجعة (1)
- تم الحل (2)
- مرفوض (3)

### List tile content

| Show | Field |
|------|-------|
| Booking | `#bookingId` |
| Customer | `customerName` |
| Worker | `workerName` |
| Reason | `reason` (1 line) |
| Status | `statusName` badge |
| Date | `createdAt` |

Tap → `/company/booking-reports/{id}`

Pull-to-refresh + pagination (`hasNextPage`).

---

## Presentation — Report detail page

**Route:** `/company/booking-reports/:id`

### Sections

1. **Header** — `#id` + status badge + `createdAt`
2. **Booking** — `#bookingId`, `bookingStatusName` (link to company booking detail if route exists)
3. **Customer** — `customerName`
4. **Worker** — `workerName`
5. **Complaint** — `reason`, `description`
6. **Resolution** (if terminal) — `adminResolutionNotes`, `resolvedByAdminName`, `resolvedAt`

### Actions (when not terminal or allow status change)

Bottom sheet / modal **تحديث الحالة**:

| Action | status | Notes |
|--------|--------|-------|
| بدء المراجعة | 1 | optional |
| تم الحل | 2 | **required** |
| رفض البلاغ | 3 | **required** |

Field label for notes: **"ملاحظات الحل"** (maps to `adminResolutionNotes`)  
Max 1000 chars, counter shown.

**On success:** snackbar **"تم تحديث حالة البلاغ"** · refresh detail.

**Hide resolve actions** when `status` is already 2 or 3 (terminal).

---

## Booking detail integration

On company booking detail (`/company/bookings/{bookingId}`):

```dart
// Fetch reports for this booking
final reports = await getCompanyBookingReports(
  filters: BookingReportFilters(bookingId: bookingId),
  page: 1,
);

// Show section if reports.isNotEmpty OR always show with empty state
Section(
  title: 'بلاغات الحجز',
  child: reports.isEmpty
    ? Text('لا توجد بلاغات على هذا الحجز')
    : ListView(...),
);
```

---

## Notifications integration

```dart
void onNotificationTap(NotificationDto n) {
  if (n.notificationType == 23 && n.relatedEntityId != null) {
    context.push('/company/booking-reports/${n.relatedEntityId}');
    return;
  }
  // existing booking notification handlers (types 10-16) use bookingId
}
```

| Type | Recipient | relatedEntityId | Navigate to |
|------|-----------|-----------------|-------------|
| 23 | Company owner | report id | `/company/booking-reports/{id}` |
| 10-16 | Company owner | booking id | booking detail |

---

## Cubit states

```dart
sealed class CompanyBookingReportsState {}
class CompanyBookingReportsLoading extends CompanyBookingReportsState {}
class CompanyBookingReportsLoaded extends CompanyBookingReportsState {
  final List<BookingReport> reports;
  final bool hasNextPage;
  final int page;
  final int? statusFilter;
}
class CompanyBookingReportsError extends CompanyBookingReportsState {
  final String message;
}

sealed class UpdateBookingReportStatusState {}
class UpdateBookingReportStatusInitial extends UpdateBookingReportStatusState {}
class UpdateBookingReportStatusLoading extends UpdateBookingReportStatusState {}
class UpdateBookingReportStatusSuccess extends UpdateBookingReportStatusState {
  final BookingReport report;
}
class UpdateBookingReportStatusError extends UpdateBookingReportStatusState {
  final String message;
}
```

---

## Dependency injection

Register in company app DI:

- `BookingReportRemoteDataSource`
- `BookingReportRepositoryImpl` → `BookingReportRepository`
- `GetCompanyBookingReportsUseCase`
- `GetBookingReportByIdUseCase`
- `UpdateBookingReportStatusUseCase`
- `CompanyBookingReportsCubit` (factory)
- `BookingReportDetailCubit` (factory)
- `UpdateBookingReportStatusCubit` (factory)

---

## Routes (go_router example)

```dart
GoRoute(
  path: '/company/booking-reports',
  builder: (_, __) => const CompanyBookingReportsPage(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (context, state) => BookingReportDetailPage(
        reportId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
),
```

---

## Testing checklist

- [ ] Company login → list loads only own company reports
- [ ] Filter by status works
- [ ] Filter by `bookingId` on booking detail section works
- [ ] View report detail for own company → 200
- [ ] View report for another company → 403 (if testable)
- [ ] Update to InReview without notes → success
- [ ] Resolve without notes → blocked client + API 400
- [ ] Resolve with notes → success, customer notified
- [ ] Reject with notes → success
- [ ] Terminal reports hide action buttons
- [ ] Notification type 23 opens correct report detail
- [ ] 401 redirects to login
- [ ] Pagination works
- [ ] Cannot call POST /api/BookingReports from company app

---

## Do NOT

- Call `POST /api/BookingReports` from company app (customer only)
- Call `GET /api/BookingReports/MyReports` or `Booking/{id}` (customer routes)
- Use `/api/Reports/*` for booking complaints
- Change booking status when resolving a report
- Parse paged response as root `List`
- Call API from widgets directly

---

## Related docs

| Topic | File |
|-------|------|
| Customer creates reports | `FLUTTER_CUSTOMER_BOOKING_REPORTS_PROMPT.md` |
| Admin dashboard module | `ADMIN_DASHBOARD_BOOKING_REPORTS_PROMPT.md` |
| Company bookings list | `FLUTTER_API_UPDATE_PROMPT.md` (Company app section) |
| Notifications | `FLUTTER_CUSTOMER_NOTIFICATIONS_PROMPT.md` (adapt for company SignalR) |

---

## PROMPT END
