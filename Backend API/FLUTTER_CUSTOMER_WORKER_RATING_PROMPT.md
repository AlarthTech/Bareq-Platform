# Flutter Customer App — Worker Rating / Reviews (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

Implement **Worker Rating (Reviews)** in the **Bareq Customer** Flutter app using Clean Architecture (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`

Customers rate a **worker** after a **completed booking**. Rating is **1–5 stars** with an optional comment. **One review per booking** — no duplicates.

---

## Business rules

| Rule | Detail |
|------|--------|
| Who can rate | **Customer** only (`userType: "Customer"`) |
| When to rate | After booking status = **Completed** (`status: 3`) — enforce in UI |
| One per booking | API returns 400 if booking already reviewed |
| Ownership | Customer must own the booking |
| Worker match | `workerId` in request must match booking's worker |
| Rating range | **1 to 5** (integer stars) |
| Comment | Optional, max **1000** characters |

---

## User flows

### Flow A — Rate from completed booking

1. Customer opens **My Bookings**
2. Completed booking (`status == 3`) shows **"قيّم العاملة"** if not yet reviewed
3. Tap → **Rate Worker** screen (stars + optional comment)
4. Submit → success snackbar → booking shows "تم التقييم"

### Flow B — Rate from booking detail

Same as Flow A — button on booking detail when completed and not reviewed.

### Flow C — View / edit own review

1. On reviewed booking → **"عرض تقييمك"**
2. Show rating, comment, date
3. Optional: **Edit** (PATCH) or **Delete** (DELETE)

### Flow D — Worker profile (read-only, public)

1. Worker detail page shows average rating + review list
2. `GET /api/Reviews/Worker/{workerId}` — **no JWT required**
3. Compute average from loaded reviews or show per-review stars

---

## API endpoints

### Create review (Customer JWT)

```http
POST /api/Reviews/CreateReview
Authorization: Bearer {customerToken}
Content-Type: application/json
```

```json
{
  "bookingId": 42,
  "workerId": 10,
  "rating": 5,
  "comment": "خدمة ممتازة، العاملة محترفة جداً"
}
```

| Field | Required | Rules |
|-------|----------|-------|
| `bookingId` | Yes | Customer's own booking |
| `workerId` | Yes | Must match booking worker |
| `rating` | Yes | Integer **1–5** |
| `comment` | No | Max 1000 chars |

**Success (201):**

```json
{
  "id": 7,
  "bookingId": 42,
  "userId": 11,
  "userName": "محمد",
  "workerId": 10,
  "workerName": "سعاد",
  "rating": 5,
  "comment": "خدمة ممتازة...",
  "createdAt": "2026-05-31T12:00:00Z"
}
```

**Errors (400):**

| Message | Meaning |
|---------|---------|
| `"الحجز غير موجود"` | Invalid bookingId |
| `"العاملة لا تطابق الحجز"` | workerId mismatch |
| `"تم التقييم على هذا الحجز مسبقاً"` | Already reviewed |
| `"العاملة غير موجودة"` | Invalid workerId |

**403:** Booking belongs to another customer.

---

### Check if booking already reviewed

```http
GET /api/Reviews/Booking/{bookingId}?page=1&pageSize=1
Authorization: Bearer {customerToken}
```

Returns `PagedResult<ReviewDTO>`. If `totalCount > 0` → already reviewed.

---

### Get worker reviews (public — no auth)

```http
GET /api/Reviews/Worker/{workerId}?page=1&pageSize=20
```

Use on worker profile to show review list and compute average rating:

```dart
double averageRating(List<Review> reviews) {
  if (reviews.isEmpty) return 0;
  return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
}
```

---

### Update own review

```http
PATCH /api/Reviews/UpdateReview/{id}
Authorization: Bearer {customerToken}
Content-Type: application/json
```

```json
{
  "rating": 4,
  "comment": "تحديث التعليق"
}
```

**Success: 204** (no body). Only review owner or Admin.

---

### Delete own review

```http
DELETE /api/Reviews/DeleteReview/{id}
Authorization: Bearer {customerToken}
```

**Success: 204**

---

### Get review by ID

```http
GET /api/Reviews/GetReviewById/{id}
Authorization: Bearer {customerToken}
```

Owner, Admin, or company owner of that booking's company can access.

---

### Load customer bookings (find rateable ones)

```http
GET /api/Bookings/User/{userId}?page=1&pageSize=20
Authorization: Bearer {customerToken}
```

Filter client-side: `status == 3` (Completed) → show rate button.

**Booking status reference:**

| status | Meaning |
|--------|---------|
| 0 | Pending |
| 1 | Approved |
| 2 | OnTheWay |
| 3 | **Completed** ← rate allowed |
| 4 | Canceled |
| 5 | Rejected |

---

## Clean Architecture structure

```
features/reviews/
├── domain/
│   ├── entities/review.dart
│   ├── repositories/review_repository.dart
│   └── usecases/
│       ├── create_review.dart
│       ├── update_review.dart
│       ├── delete_review.dart
│       ├── get_reviews_by_worker.dart
│       └── get_reviews_by_booking.dart
├── data/
│   ├── models/
│   │   ├── review_model.dart
│   │   └── create_review_request.dart
│   ├── datasources/review_remote_datasource.dart
│   └── repositories/review_repository_impl.dart
└── presentation/
    ├── state/
    │   ├── create_review_cubit.dart
    │   ├── worker_reviews_cubit.dart
    │   └── my_review_cubit.dart
    ├── pages/
    │   ├── rate_worker_page.dart
    │   ├── my_review_page.dart
    │   └── worker_reviews_section.dart   # embed in worker profile
    └── widgets/
        ├── star_rating_input.dart
        ├── star_rating_display.dart
        └── review_card.dart
```

---

## Domain layer

```dart
class Review {
  final int id;
  final int bookingId;
  final int userId;
  final String? userName;
  final int workerId;
  final String? workerName;
  final int rating;       // 1-5
  final String? comment;
  final DateTime createdAt;
}

abstract class ReviewRepository {
  Future<Either<Failure, Review>> createReview({
    required int bookingId,
    required int workerId,
    required int rating,
    String? comment,
  });

  Future<Either<Failure, void>> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
  });

  Future<Either<Failure, void>> deleteReview(int reviewId);

  Future<Either<Failure, PagedResult<Review>>> getReviewsByWorker(
    int workerId, {int page = 1});

  Future<Either<Failure, PagedResult<Review>>> getReviewsByBooking(
    int bookingId, {int page = 1});
}
```

---

## Data layer

```dart
Future<ReviewModel> createReview(CreateReviewRequest request) async {
  final response = await _client.post(
    '/api/Reviews/CreateReview',
    data: request.toJson(),
  );
  return ReviewModel.fromJson(response.data);
}

Future<PagedResult<ReviewModel>> getReviewsByWorker(int workerId, {int page = 1}) async {
  final response = await _client.get(
    '/api/Reviews/Worker/$workerId',
    queryParameters: {'page': page, 'pageSize': 20},
  );
  return PagedResult.fromJson(response.data, ReviewModel.fromJson);
}

Future<bool> hasReviewForBooking(int bookingId) async {
  final result = await getReviewsByBooking(bookingId, pageSize: 1);
  return result.fold((_) => false, (paged) => paged.totalCount > 0);
}
```

---

## Presentation — Rate Worker page

### Navigation params

```dart
RateWorkerPage({
  required int bookingId,
  required int workerId,
  required String workerName,
  required int companyId,      // display only
  required String? companyName,
});
```

### Form UI (RTL Arabic)

| Element | Details |
|---------|---------|
| Header | "تقييم العاملة: {workerName}" |
| Stars input | 1–5 tappable stars (required) |
| Comment | Multiline, optional, max 1000, character counter |
| Submit | **"إرسال التقييم"** — disabled until rating ≥ 1 |

### Client validation

```dart
if (rating < 1 || rating > 5) => 'يرجى اختيار التقييم';
if (comment != null && comment.length > 1000) => 'التعليق طويل جداً';
```

### On success

Snackbar: **"شكراً! تم إرسال تقييمك بنجاح."**  
Pop back to booking detail / refresh booking list.

### On error `تم التقييم على هذا الحجز مسبقاً`

Show message and navigate to existing review view.

---

## Presentation — Booking list / detail integration

```dart
// Pseudologic for booking card actions
if (booking.status == 3) {
  final hasReview = await checkReviewExists(booking.id);
  if (!hasReview)
    showButton('قيّم العاملة', onTap: () => openRateWorkerPage(booking));
  else
    showButton('عرض تقييمك', onTap: () => openMyReviewPage(booking.id));
}
```

Call `GET /api/Reviews/Booking/{bookingId}` to determine `hasReview`.

Cache per booking in Cubit state to avoid repeated calls.

---

## Presentation — Worker profile reviews section

Embed in existing worker detail page:

```dart
WorkerReviewsSection(workerId: worker.id)
```

- Fetch `GET /api/Reviews/Worker/{workerId}`
- Show: **⭐ 4.5** (average) · **(12 تقييم)**
- List of `ReviewCard` widgets: stars, comment, userName (or "عميل"), date
- Paginate or "عرض المزيد" if `hasNextPage`
- **No JWT** needed for this endpoint

### ReviewCard widget

```
┌─────────────────────────────┐
│ ★★★★★  محمد                │
│ "خدمة ممتازة..."            │
│ 2026-05-31                  │
└─────────────────────────────┘
```

---

## Star rating widgets

### Input (interactive)

```dart
class StarRatingInput extends StatelessWidget {
  final int value;              // 0-5, 0 = none selected
  final ValueChanged<int> onChanged;
  // 5 Icon(Icons.star) / Icon(Icons.star_border)
  // Color: amber/gold when selected
}
```

### Display (read-only)

```dart
class StarRatingDisplay extends StatelessWidget {
  final double rating;          // e.g. 4.0 — show full/half/empty stars
  final double size;
}
```

---

## My review page (view / edit / delete)

Load via `GET /api/Reviews/Booking/{bookingId}` → first item.

**View mode:** stars, comment, date.

**Edit mode:** same form as create → `PATCH UpdateReview/{id}`.

**Delete:** confirm dialog → `DELETE DeleteReview/{id}` → refresh booking state.

---

## Cubit states

```dart
sealed class CreateReviewState {}
class CreateReviewInitial extends CreateReviewState {}
class CreateReviewLoading extends CreateReviewState {}
class CreateReviewSuccess extends CreateReviewState { final Review review; }
class CreateReviewError extends CreateReviewState { final String message; }

sealed class WorkerReviewsState {}
class WorkerReviewsLoading extends WorkerReviewsState {}
class WorkerReviewsLoaded extends WorkerReviewsState {
  final List<Review> reviews;
  final double averageRating;
  final bool hasNextPage;
}
class WorkerReviewsError extends WorkerReviewsState { final String message; }
```

---

## Dependency injection

Register:

- `ReviewRemoteDataSource`
- `ReviewRepositoryImpl`
- `CreateReviewUseCase`, `UpdateReviewUseCase`, `DeleteReviewUseCase`
- `GetReviewsByWorkerUseCase`, `GetReviewsByBookingUseCase`
- `CreateReviewCubit`, `WorkerReviewsCubit` (factory)

---

## Testing checklist

- [ ] Completed booking shows "قيّم العاملة" when no review exists
- [ ] Completed booking shows "عرض تقييمك" when already reviewed
- [ ] Non-completed bookings hide rate button
- [ ] Create review with 5 stars + comment → 201
- [ ] Duplicate review on same booking → 400 Arabic message
- [ ] workerId mismatch → 400
- [ ] Worker profile shows public reviews without login
- [ ] Average rating calculated correctly
- [ ] Update own review (rating + comment) → 204
- [ ] Delete own review → booking shows rate button again
- [ ] Comment max 1000 enforced client-side
- [ ] 401 redirects to login on protected endpoints

---

## Do NOT

- Allow rating before booking is **Completed** (status 3)
- Call `CreateReview` from widgets directly — use repository + use case
- Send rating 0 or > 5
- Parse review lists as root `List` — use `PagedResult`
- Show edit/delete on other customers' reviews

---

## PROMPT END
