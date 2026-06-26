# Flutter Customer App — Reports Feature (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

Implement **Report Worker / Report Company** in the **Bareq Customer** Flutter app using Clean Architecture (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`

Customers can submit a report against a **worker** or a **company**. They can only view **their own** reports — not reports from other customers. Company owners cannot see reports against them.

---

## User flows

### Flow A — Report from worker profile

1. Customer opens worker detail page
2. Taps **"إبلاغ عن عاملة"**
3. Enters description (min 10 chars) → submit
4. Success message → optional navigate to "My Reports"

### Flow B — Report from company profile

1. Customer opens company detail page
2. Taps **"إبلاغ عن شركة"**
3. Enters description → submit

### Flow C — My reports list

1. Profile / settings → **"بلاغاتي"**
2. List of own reports with status badges
3. Tap row → report detail (read-only)
4. Optional: delete own report

---

## API endpoints (Customer JWT required)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/Reports/CreateReport` | Submit report |
| GET | `/api/Reports/GetMyReports?page=1&pageSize=20` | Own reports |
| GET | `/api/Reports/GetReportById/{id}` | Single report (owner only) |
| DELETE | `/api/Reports/DeleteReport/{id}` | Delete own report |

> **403** if customer tries to view another user's report.  
> **`adminNotes`** is always `null` for customers — never shown in UI.

---

## Create report

```http
POST /api/Reports/CreateReport
Authorization: Bearer {customerToken}
Content-Type: application/json
```

**Report a worker:**

```json
{
  "targetType": 1,
  "workerId": 10,
  "description": "العاملة تأخرت ساعتين عن الموعد المتفق عليه"
}
```

**Report a company:**

```json
{
  "targetType": 2,
  "companyId": 5,
  "description": "الشركة لم تلتزم بالخدمة المتفق عليها"
}
```

| Field | Rules |
|-------|--------|
| `targetType` | `1` = Worker · `2` = Company |
| `workerId` | Required when `targetType = 1` |
| `companyId` | Required when `targetType = 2` |
| `description` | Required, min **10**, max **2000** chars |

**Do NOT** send both `workerId` and `companyId` in the same request.

**Success (201):** returns `ReportDTO`

**Errors (400):** Arabic messages e.g.:
- `"يجب تحديد العاملة المراد الإبلاغ عنها."`
- `"يجب تحديد الشركة المراد الإبلاغ عنها."`
- `"لا يمكن الإبلاغ عن عاملة وشركة في نفس البلاغ."`
- `"وصف البلاغ يجب أن يكون 10 أحرف على الأقل."`

---

## My reports list

```http
GET /api/Reports/GetMyReports?page=1&pageSize=20
Authorization: Bearer {customerToken}
```

**Response:** `PagedResult<Report>`

```json
{
  "items": [
    {
      "id": 1,
      "userId": 11,
      "userName": "محمد",
      "targetType": 1,
      "targetTypeName": "عاملة",
      "workerId": 10,
      "workerName": "سعاد",
      "companyId": null,
      "companyName": null,
      "description": "...",
      "status": 0,
      "statusName": "قيد الانتظار",
      "adminNotes": null,
      "createdAt": "2026-05-31T11:00:00Z",
      "updatedAt": null
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

Never parse as root `List` — always use `PagedResult`.

---

## Report detail

```http
GET /api/Reports/GetReportById/1
Authorization: Bearer {customerToken}
```

Returns single report if caller is the owner. **403** otherwise.

---

## Delete own report

```http
DELETE /api/Reports/DeleteReport/1
Authorization: Bearer {customerToken}
```

**Success: 204**

---

## Status display (read-only for customer)

| status | statusName | Color |
|--------|------------|-------|
| 0 | قيد الانتظار | amber |
| 1 | قيد المراجعة | blue |
| 2 | تم الحل | green |
| 3 | مرفوض | grey |

Show `statusName` from API — do not hardcode if API returns Arabic label.

---

## Clean Architecture structure

```
features/reports/
├── domain/
│   ├── entities/report.dart
│   ├── repositories/report_repository.dart
│   └── usecases/
│       ├── create_report.dart
│       ├── get_my_reports.dart
│       ├── get_report_by_id.dart
│       └── delete_report.dart
├── data/
│   ├── models/
│   │   ├── report_model.dart
│   │   └── create_report_request.dart
│   ├── datasources/report_remote_datasource.dart
│   └── repositories/report_repository_impl.dart
└── presentation/
    ├── state/
    │   ├── create_report_cubit.dart
    │   └── my_reports_cubit.dart
    ├── pages/
    │   ├── create_report_page.dart
    │   ├── my_reports_page.dart
    │   └── report_detail_page.dart
    └── widgets/
        ├── report_status_badge.dart
        └── report_target_tile.dart
```

---

## Domain layer

```dart
enum ReportTargetType { worker, company } // maps to 1, 2

enum ReportStatus { pending, underReview, resolved, dismissed } // 0-3

abstract class ReportRepository {
  Future<Either<Failure, Report>> createWorkerReport({
    required int workerId,
    required String description,
  });

  Future<Either<Failure, Report>> createCompanyReport({
    required int companyId,
    required String description,
  });

  Future<Either<Failure, PagedResult<Report>>> getMyReports({
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Report>> getReportById(int id);

  Future<Either<Failure, void>> deleteReport(int id);
}
```

---

## Data layer

```dart
// Create worker report
Future<ReportModel> createWorkerReport(int workerId, String description) async {
  final response = await _client.post(
    '/api/Reports/CreateReport',
    data: {
      'targetType': 1,
      'workerId': workerId,
      'description': description.trim(),
    },
  );
  return ReportModel.fromJson(response.data);
}

// Create company report
Future<ReportModel> createCompanyReport(int companyId, String description) async {
  final response = await _client.post(
    '/api/Reports/CreateReport',
    data: {
      'targetType': 2,
      'companyId': companyId,
      'description': description.trim(),
    },
  );
  return ReportModel.fromJson(response.data);
}

// My reports
Future<PagedResult<ReportModel>> getMyReports({int page = 1}) async {
  final response = await _client.get(
    '/api/Reports/GetMyReports',
    queryParameters: {'page': page, 'pageSize': 20},
  );
  return PagedResult.fromJson(response.data, ReportModel.fromJson);
}
```

---

## Presentation — Create report page

### Params (from navigation)

```dart
CreateReportPage({
  required ReportTargetType targetType,
  required int targetId,        // workerId or companyId
  required String targetName,   // display only
});
```

### Form

| Label | Field |
|-------|-------|
| الإبلاغ عن | Read-only: worker/company name |
| وصف البلاغ | Multiline, min 10 chars |
| | Character counter: `{length}/2000` |

**Validation (client-side before submit):**
- Description not empty
- Length >= 10
- Length <= 2000

**Submit button:** **"إرسال البلاغ"**

**On success:** Snackbar **"تم إرسال بلاغك بنجاح. سيتم مراجعته من قبل الإدارة."** → pop or go to My Reports.

**On error:** Show API Arabic `message`.

---

## Presentation — Entry points

### Worker detail page

Add icon button or list tile:

```dart
ListTile(
  leading: Icon(Icons.report_outlined, color: Colors.red.shade400),
  title: Text('إبلاغ عن عاملة'),
  onTap: () => context.push('/reports/create', extra: {
    'targetType': ReportTargetType.worker,
    'targetId': worker.id,
    'targetName': worker.fullName,
  }),
)
```

### Company detail page

Same pattern with `ReportTargetType.company` and `company.id`.

### Profile / settings

```dart
ListTile(
  leading: Icon(Icons.list_alt),
  title: Text('بلاغاتي'),
  onTap: () => context.push('/reports/my'),
)
```

---

## My reports page

- Paginated list (infinite scroll or page buttons using `hasNextPage`)
- Each tile: target name, `targetTypeName`, `statusName` badge, date, description preview
- Tap → `ReportDetailPage`
- Pull-to-refresh

### Report detail page (read-only)

- Target type + name
- Full description
- Status badge
- Created date
- **Delete button** with confirm dialog → `DeleteReport`

---

## Cubit states

```dart
sealed class CreateReportState {}
class CreateReportInitial extends CreateReportState {}
class CreateReportLoading extends CreateReportState {}
class CreateReportSuccess extends CreateReportState { final Report report; }
class CreateReportError extends CreateReportState { final String message; }

sealed class MyReportsState {}
class MyReportsLoading extends MyReportsState {}
class MyReportsLoaded extends MyReportsState {
  final List<Report> reports;
  final bool hasNextPage;
  final int page;
}
class MyReportsError extends MyReportsState { final String message; }
```

---

## Dependency injection

Register:

- `ReportRemoteDataSource`
- `ReportRepositoryImpl`
- `CreateReportUseCase`, `GetMyReportsUseCase`, `GetReportByIdUseCase`, `DeleteReportUseCase`
- `CreateReportCubit` (factory)
- `MyReportsCubit` (factory)

---

## Testing checklist

- [ ] Report worker from worker profile → 201 success
- [ ] Report company from company profile → 201 success
- [ ] Description < 10 chars blocked client-side
- [ ] My reports lists only own reports
- [ ] Status badge displays `statusName` from API
- [ ] Report detail loads for own report
- [ ] Delete own report works (204)
- [ ] `adminNotes` never displayed (always null for customer)
- [ ] 401 redirects to login
- [ ] Pagination works on GetMyReports

---

## Do NOT

- Call API from widgets directly
- Send both workerId and companyId
- Show adminNotes (always null for customer)
- Allow Company app to call these endpoints (Customer role only for create/list)
- Parse GetMyReports as root List

---

## PROMPT END
