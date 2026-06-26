# Flutter Customer App — Worker & Company Ratings Display (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

Display **average star ratings** in the customer app:

1. **Each worker** — show average rating on worker cards and worker profile
2. **Each company** — show company rating = **average of its workers' average ratings** (workers with no reviews are excluded)

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`

All rating summary endpoints are **public** — no JWT required.

---

## Rating rules

| Display | Formula | Example |
|---------|---------|---------|
| Worker | `sum(ratings) / totalReviews` for that worker | 4 reviews: 5,4,5,4 → **4.5** |
| Company | `average(workerAverage₁, workerAverage₂, …)` | Worker A=4.5, Worker B=5.0 → **4.75** |
| No reviews | Show **"لا توجد تقييمات"** or hide stars | Never show 0.0 as if rated |

**Company rating is NOT** the average of all review scores combined — it is the **mean of each worker's average** (each worker counts equally).

---

## API endpoints

### 1. Single worker average (worker card / profile header)

```http
GET /api/Reviews/Worker/{workerId}/Summary
```

**No auth required.**

**Response (200):**

```json
{
  "averageRating": 4.5,
  "totalReviews": 12
}
```

**Empty worker (no reviews):**

```json
{
  "averageRating": 0,
  "totalReviews": 0
}
```

**404** — worker not found or not active.

---

### 2. Company average (company detail header)

```http
GET /api/Reviews/Company/{companyId}/Summary
```

**No auth required.**

**Response (200):**

```json
{
  "companyId": 5,
  "averageRating": 4.75,
  "totalReviews": 48,
  "ratedWorkersCount": 8,
  "totalActiveWorkers": 12
}
```

| Field | Use in UI |
|-------|-----------|
| `averageRating` | Stars + number (e.g. ⭐ 4.8) |
| `totalReviews` | "(48 تقييم)" |
| `ratedWorkersCount` / `totalActiveWorkers` | Optional subtitle: "8 عاملات مُقيّمة" |

**404** — company not found, not verified, or not active.

---

### 3. All worker ratings for a company (worker list on company page)

Use **one request** instead of calling Summary per worker:

```http
GET /api/Reviews/Company/{companyId}/WorkerSummaries
```

**Response (200):**

```json
[
  { "workerId": 10, "averageRating": 4.8, "totalReviews": 15 },
  { "workerId": 12, "averageRating": 4.2, "totalReviews": 6 }
]
```

Workers with **zero reviews are omitted** from this list — treat missing workerId as no rating.

---

### 4. Full review list (worker profile — optional)

```http
GET /api/Reviews/Worker/{workerId}?page=1&pageSize=20
```

Use for review comments below the summary header. Summary endpoint is preferred for the star display (no pagination needed).

---

## Clean Architecture structure

```
features/ratings/
├── domain/
│   ├── entities/
│   │   ├── rating_summary.dart
│   │   ├── company_rating_summary.dart
│   │   └── worker_rating_summary.dart
│   ├── repositories/rating_repository.dart
│   └── usecases/
│       ├── get_worker_rating_summary.dart
│       ├── get_company_rating_summary.dart
│       └── get_company_worker_summaries.dart
├── data/
│   ├── models/rating_summary_model.dart
│   ├── datasources/rating_remote_datasource.dart
│   └── repositories/rating_repository_impl.dart
└── presentation/
    ├── widgets/
    │   ├── star_rating_display.dart      # reusable ⭐ 4.5 (12)
    │   └── rating_badge.dart             # compact for list cards
    └── extensions/rating_formatters.dart
```

---

## Domain entities

```dart
class RatingSummary {
  final double averageRating;
  final int totalReviews;

  const RatingSummary({required this.averageRating, required this.totalReviews});

  bool get hasReviews => totalReviews > 0;
}

class CompanyRatingSummary extends RatingSummary {
  final int companyId;
  final int ratedWorkersCount;
  final int totalActiveWorkers;

  const CompanyRatingSummary({
    required this.companyId,
    required super.averageRating,
    required super.totalReviews,
    required this.ratedWorkersCount,
    required this.totalActiveWorkers,
  });
}

class WorkerRatingSummary extends RatingSummary {
  final int workerId;

  const WorkerRatingSummary({
    required this.workerId,
    required super.averageRating,
    required super.totalReviews,
  });
}
```

---

## Data layer

```dart
class RatingRemoteDataSource {
  final Dio _client;

  Future<RatingSummaryModel> getWorkerSummary(int workerId) async {
    final res = await _client.get('/api/Reviews/Worker/$workerId/Summary');
    return RatingSummaryModel.fromJson(res.data);
  }

  Future<CompanyRatingSummaryModel> getCompanySummary(int companyId) async {
    final res = await _client.get('/api/Reviews/Company/$companyId/Summary');
    return CompanyRatingSummaryModel.fromJson(res.data);
  }

  Future<List<WorkerRatingSummaryModel>> getCompanyWorkerSummaries(int companyId) async {
    final res = await _client.get('/api/Reviews/Company/$companyId/WorkerSummaries');
    final list = res.data as List;
    return list.map((e) => WorkerRatingSummaryModel.fromJson(e)).toList();
  }
}
```

---

## Formatting helpers

```dart
extension RatingFormatters on double {
  /// Display: 4.5 or 5.0 → "4.5" / "5.0"
  String get ratingLabel => hasReviews ? toStringAsFixed(1) : '—';

  bool get hasReviews => this > 0;
}

String reviewCountLabel(int count, {String locale = 'ar'}) {
  if (count == 0) return locale == 'ar' ? 'لا توجد تقييمات' : 'No reviews';
  if (locale == 'ar') return count == 1 ? '(تقييم واحد)' : '($count تقييم)';
  return count == 1 ? '(1 review)' : '($count reviews)';
}
```

---

## UI — Worker card (company worker list)

```
┌────────────────────────────────────┐
│ [Photo]  سعاد أحمد                 │
│          ⭐⭐⭐⭐☆ 4.5 (12 تقييم)   │
│          5 سنوات خبرة              │
└────────────────────────────────────┘
```

### Flow

1. Open company detail → call `GET /api/Reviews/Company/{id}/WorkerSummaries` once
2. Build `Map<int, WorkerRatingSummary>` keyed by `workerId`
3. For each worker card, lookup summary from map
4. If worker not in map → show **"لا توجد تقييمات"** (grey stars or hidden)

```dart
Widget buildWorkerRating(int workerId, Map<int, WorkerRatingSummary> summaries) {
  final summary = summaries[workerId];
  if (summary == null || !summary.hasReviews) {
    return Text('لا توجد تقييمات', style: TextStyle(color: Colors.grey));
  }
  return StarRatingDisplay(
    rating: summary.averageRating,
    reviewCount: summary.totalReviews,
  );
}
```

---

## UI — Worker profile page

1. Header: `GET /api/Reviews/Worker/{workerId}/Summary`
2. Below: paginated reviews from `GET /api/Reviews/Worker/{workerId}`

```dart
// Profile header
Row(
  children: [
    StarRatingDisplay(rating: summary.averageRating, reviewCount: summary.totalReviews),
    if (summary.hasReviews) Text('${summary.averageRating.toStringAsFixed(1)}'),
  ],
)
```

---

## UI — Company detail page

1. Company header: `GET /api/Reviews/Company/{companyId}/Summary`

```
┌────────────────────────────────────┐
│  شركة النور للتنظيف                │
│  ⭐⭐⭐⭐⭐ 4.8 (48 تقييم)          │
│  8 عاملات مُقيّمة · 12 عاملة      │
└────────────────────────────────────┘
```

2. Worker list section: use `WorkerSummaries` map (see above)

**Load in parallel:**

```dart
final results = await Future.wait([
  getCompanySummary(companyId),
  getCompanyWorkerSummaries(companyId),
  getActiveWorkers(companyId),  // existing workers API
]);
```

---

## Reusable `StarRatingDisplay` widget

```dart
class StarRatingDisplay extends StatelessWidget {
  final double rating;       // 0–5
  final int reviewCount;
  final double starSize;

  const StarRatingDisplay({
    required this.rating,
    required this.reviewCount,
    this.starSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Text('لا توجد تقييمات', style: Theme.of(context).textTheme.bodySmall);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = rating >= i + 1;
          final half = !filled && rating > i && rating < i + 1;
          return Icon(
            filled ? Icons.star : (half ? Icons.star_half : Icons.star_border),
            color: Colors.amber,
            size: starSize,
          );
        }),
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)} ${reviewCountLabel(reviewCount)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
```

---

## Caching & performance

| Screen | Strategy |
|--------|----------|
| Company detail | Cache `CompanySummary` + `WorkerSummaries` for session (invalidate on pull-to-refresh) |
| Worker profile | Cache summary 5 min |
| Search / browse lists | Optional: skip rating on list, show only on detail |

Do **not** fetch all review pages to compute average — use **Summary** endpoints.

---

## After customer submits a review

Invalidate caches for:

- `Worker/{workerId}/Summary`
- `Company/{companyId}/Summary`
- `Company/{companyId}/WorkerSummaries`

Refresh ratings on booking detail / worker profile when user returns from rate flow.

---

## Acceptance checklist

- [ ] Worker card shows ⭐ + average + count when reviews exist
- [ ] Worker card shows "لا توجد تقييمات" when no reviews
- [ ] Worker profile header uses Summary endpoint
- [ ] Company detail shows company average (mean of worker averages)
- [ ] Company worker list uses single `WorkerSummaries` call (not N+1)
- [ ] Ratings work without login (public endpoints)
- [ ] Half-star display for 4.3, 4.7 etc.
- [ ] Ratings refresh after customer submits a review

---

## Do NOT

- Compute average by fetching all review pages client-side
- Show `0.0` stars when `totalReviews == 0`
- Use weighted company average (all reviews combined) unless product explicitly changes — API returns **mean of worker averages**
- Call Summary endpoint from widgets directly — use repository + use case

## PROMPT END
