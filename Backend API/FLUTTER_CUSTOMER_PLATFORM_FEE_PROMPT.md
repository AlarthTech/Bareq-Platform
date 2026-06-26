# Flutter Customer App — Platform Fee & Booking Pricing (Copy-Paste Prompt)

Copy everything below the line into Cursor / your Flutter **Bareq Customer** app agent.

---

## PROMPT START

Implement **Platform Fee (رسوم المنصة)** and **booking price breakdown** in the **Bareq Customer** Flutter app using **Clean Architecture** (Presentation → Domain → Data).

**Base URL:** `http://102.203.200.55:5545`  
**Swagger:** `http://102.203.200.55:5545/swagger`  
**Backend reference:** `PLATFORM_FEE_IMPLEMENTATION.md`

Customers must see a clear price summary **before confirming a booking**:

```
سعر الخدمة        100.00 د.ل
رسوم المنصة         5.00 د.ل
─────────────────────────────
الإجمالي          105.00 د.ل
```

All amounts come from the **server** — never calculate totals in the app.

---

## Business rules

| Rule | Detail |
|------|--------|
| Price source | `POST /api/v1/bookings/price-preview` before confirm |
| Create booking | `POST /api/Bookings/CreateBooking` — send **no** price fields |
| `isMonthly` | Send on preview + create when user selects monthly work type |
| Stored prices | Booking list/detail use API `servicePrice`, `platformFeeAmount`, `totalPrice` |
| Legacy bookings | If all prices are `0`, show **"—"** or **"غير متوفر"** |
| Platform fee label (AR) | **رسوم المنصة** |
| Currency | **د.ل** (Libyan Dinar) |

---

## User flows

### Flow A — Booking confirmation screen

1. Customer selects company, worker, work type, date, time, location (existing flow).
2. On **Review & Confirm** step → call **price-preview** with current selections.
3. Show loading skeleton while fetching prices.
4. Display breakdown card (service + platform fee + total).
5. **Confirm** → `CreateBooking` with same params + `isMonthly` (no prices in body).
6. On success → navigate to booking detail / success screen.

### Flow B — Price updates when inputs change

Whenever user changes worker, work type, date, or monthly toggle:

- Debounce **300–500 ms**
- Re-call `price-preview`
- Update breakdown UI

### Flow C — My bookings list & detail

- List row: show **الإجمالي** (`totalPrice`)
- Detail: full **تفاصيل السعر** card from stored booking fields (not price-preview)

---

## API endpoints

### Price preview (Customer JWT)

```http
POST /api/v1/bookings/price-preview
Authorization: Bearer {customerToken}
Content-Type: application/json
```

**Request** (same fields as create booking, minus address if not yet chosen — include address/location when required by your flow):

```json
{
  "companyId": 1,
  "workerId": 10,
  "workTypeId": 3,
  "bookingDate": "2026-06-15T00:00:00Z",
  "startDate": "08:00",
  "endDate": "18:00",
  "isMonthly": false
}
```

**Success (200):**

```json
{
  "servicePrice": 100,
  "platformFeeAmount": 5,
  "totalPrice": 105
}
```

**Errors (400):**

```json
{ "message": "العاملة غير متاحة للحجز" }
```

Common messages: company/worker/work type invalid, worker not linked to work type, monthly price not available.

---

### Create booking (unchanged path, new field)

```http
POST /api/Bookings/CreateBooking
Authorization: Bearer {customerToken}
Content-Type: application/json
```

```json
{
  "companyId": 1,
  "workerId": 10,
  "workTypeId": 3,
  "bookingDate": "2026-06-15T00:00:00Z",
  "startDate": "08:00",
  "endDate": "18:00",
  "address": "طرابلس - حي الأندلس",
  "userLocationId": null,
  "isMonthly": false
}
```

**Do NOT send:** `servicePrice`, `platformFeeAmount`, `totalPrice`.

**Success (201):** `BookingDTO` includes stored prices:

```json
{
  "id": 42,
  "servicePrice": 100,
  "platformFeeAmount": 5,
  "totalPrice": 105,
  "isMonthlyPricing": false,
  "status": 0
}
```

---

### My bookings

```http
GET /api/Bookings/User/{userId}?page=1&pageSize=20
GET /api/Bookings/GetBookingById/{id}
```

Response includes `servicePrice`, `platformFeeAmount`, `totalPrice`, `isMonthlyPricing`.

---

## Clean Architecture structure

```
features/booking_pricing/
├── domain/
│   ├── entities/booking_price_breakdown.dart
│   ├── repositories/booking_pricing_repository.dart
│   └── usecases/
│       ├── preview_booking_price.dart
│       └── (create_booking stays in bookings feature)
├── data/
│   ├── models/
│   │   ├── booking_price_preview_request_model.dart
│   │   └── booking_price_preview_model.dart
│   ├── datasources/booking_pricing_remote_datasource.dart
│   └── repositories/booking_pricing_repository_impl.dart
└── presentation/
    ├── state/booking_price_preview_cubit.dart
    └── widgets/
        ├── booking_price_breakdown_card.dart
        └── booking_price_breakdown_skeleton.dart

features/bookings/
├── domain/entities/booking.dart          # add price fields
├── data/models/booking_model.dart         # add price fields
└── presentation/
    ├── pages/booking_confirm_page.dart   # embed breakdown
    └── widgets/booking_list_price_chip.dart
```

---

## Domain layer

```dart
class BookingPriceBreakdown {
  final double servicePrice;
  final double platformFeeAmount;
  final double totalPrice;

  const BookingPriceBreakdown({
    required this.servicePrice,
    required this.platformFeeAmount,
    required this.totalPrice,
  });

  bool get hasPricing => totalPrice > 0 || servicePrice > 0;
}

abstract class BookingPricingRepository {
  Future<Either<Failure, BookingPriceBreakdown>> previewPrice(
    BookingPricePreviewParams params,
  );
}

class BookingPricePreviewParams {
  final int companyId;
  final int workerId;
  final int workTypeId;
  final DateTime bookingDate;
  final String startDate;
  final String endDate;
  final bool isMonthly;

  const BookingPricePreviewParams({
    required this.companyId,
    required this.workerId,
    required this.workTypeId,
    required this.bookingDate,
    required this.startDate,
    required this.endDate,
    required this.isMonthly,
  });
}
```

```dart
class PreviewBookingPrice {
  final BookingPricingRepository repository;
  PreviewBookingPrice(this.repository);

  Future<Either<Failure, BookingPriceBreakdown>> call(
    BookingPricePreviewParams params,
  ) => repository.previewPrice(params);
}
```

---

## Data layer

```dart
class BookingPricePreviewModel {
  final double servicePrice;
  final double platformFeeAmount;
  final double totalPrice;

  factory BookingPricePreviewModel.fromJson(Map<String, dynamic> json) =>
      BookingPricePreviewModel(
        servicePrice: (json['servicePrice'] as num).toDouble(),
        platformFeeAmount: (json['platformFeeAmount'] as num).toDouble(),
        totalPrice: (json['totalPrice'] as num).toDouble(),
      );

  BookingPriceBreakdown toEntity() => BookingPriceBreakdown(
        servicePrice: servicePrice,
        platformFeeAmount: platformFeeAmount,
        totalPrice: totalPrice,
      );
}
```

```dart
Future<BookingPricePreviewModel> previewPrice(
  BookingPricePreviewRequestModel request,
) async {
  final response = await _client.post(
    '/api/v1/bookings/price-preview',
    data: request.toJson(),
  );
  return BookingPricePreviewModel.fromJson(response.data);
}
```

---

## Presentation — `BookingPricePreviewCubit`

States:

```dart
sealed class BookingPricePreviewState {}

class BookingPricePreviewInitial extends BookingPricePreviewState {}
class BookingPricePreviewLoading extends BookingPricePreviewState {}
class BookingPricePreviewLoaded extends BookingPricePreviewState {
  final BookingPriceBreakdown breakdown;
  BookingPricePreviewLoaded(this.breakdown);
}
class BookingPricePreviewError extends BookingPricePreviewState {
  final String message;
  BookingPricePreviewError(this.message);
}
```

```dart
Future<void> loadPreview(BookingPricePreviewParams params) async {
  emit(BookingPricePreviewLoading());
  final result = await previewBookingPrice(params);
  result.fold(
    (f) => emit(BookingPricePreviewError(f.message)),
    (b) => emit(BookingPricePreviewLoaded(b)),
  );
}
```

Call `loadPreview` from confirm page `initState` and whenever form inputs change (debounced).

---

## UI — Price breakdown card (RTL)

```dart
class BookingPriceBreakdownCard extends StatelessWidget {
  final BookingPriceBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ملخص السعر', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row('سعر الخدمة', breakdown.servicePrice),
            _row('رسوم المنصة', breakdown.platformFeeAmount),
            const Divider(),
            _row('الإجمالي', breakdown.totalPrice, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            '${amount.toFixed(2)} د.ل',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
```

### Confirm button rules

- Disabled while `BookingPricePreviewLoading`
- Disabled on `BookingPricePreviewError` (show retry)
- Enabled only when `BookingPricePreviewLoaded`
- Label: **"تأكيد الحجز — {total} د.ل"** (optional)

### Error & retry

```dart
if (state is BookingPricePreviewError)
  Column(
    children: [
      Text(state.message),
      TextButton(
        onPressed: () => cubit.loadPreview(params),
        child: const Text('إعادة المحاولة'),
      ),
    ],
  );
```

---

## Monthly pricing toggle

When work type supports monthly pricing (`monthlyPrice != null` on work type from API):

- Show toggle: **"حجز شهري"**
- `isMonthly: true` → preview uses monthly price
- Pass same flag to `CreateBooking`

If user enables monthly but API returns error **"نوع العمل المحدد لا يدعم التسعير الشهري"**, show message and disable confirm.

---

## Update `Booking` entity (list & detail)

```dart
class Booking {
  // ... existing fields
  final double servicePrice;
  final double platformFeeAmount;
  final double totalPrice;
  final bool isMonthlyPricing;
}
```

### List item

Show chip: **`105.00 د.ل`** using `totalPrice`.

### Detail page — stored prices (read-only)

Reuse `BookingPriceBreakdownCard` with values from `booking` entity — **do not** call price-preview on detail (historical snapshot).

```dart
if (booking.totalPrice > 0)
  BookingPriceBreakdownCard(
    breakdown: BookingPriceBreakdown(
      servicePrice: booking.servicePrice,
      platformFeeAmount: booking.platformFeeAmount,
      totalPrice: booking.totalPrice,
    ),
  )
else
  const Text('تفاصيل السعر غير متوفرة لهذا الحجز');
```

---

## DI registration

```dart
// injection.dart
sl.registerLazySingleton<BookingPricingRemoteDataSource>(...);
sl.registerLazySingleton<BookingPricingRepository>(
  () => BookingPricingRepositoryImpl(sl()),
);
sl.registerLazySingleton(() => PreviewBookingPrice(sl()));
sl.registerFactory(() => BookingPricePreviewCubit(sl()));
```

---

## Integration checklist (confirm screen)

Wire into existing booking wizard **last step** before submit:

1. Collect `companyId`, `workerId`, `workTypeId`, `bookingDate`, `startDate`, `endDate`, `isMonthly`.
2. `BlocProvider` → `BookingPricePreviewCubit` → `loadPreview`.
3. Show `BookingPriceBreakdownCard` above confirm button.
4. On confirm → existing `CreateBooking` use case with `isMonthly` added to request model.
5. Do not pass preview amounts to create API.

---

## Acceptance checklist

- [ ] Confirm screen shows service price, platform fee, total from price-preview
- [ ] Arabic label **رسوم المنصة** visible
- [ ] Changing worker/work type/date refreshes preview (debounced)
- [ ] Confirm disabled until preview loads successfully
- [ ] Create booking sends `isMonthly` but **no** price fields
- [ ] Booking detail shows stored breakdown from API
- [ ] My bookings list shows total price
- [ ] Monthly toggle updates preview correctly
- [ ] 400 errors show Arabic `message` from API
- [ ] Clean Architecture: no API calls from widgets
- [ ] No client-side `servicePrice + platformFee` calculation for display

---

## Do NOT

- Send `servicePrice`, `platformFeeAmount`, or `totalPrice` in `CreateBooking`
- Calculate total in Flutter for display (trust preview + stored booking fields)
- Call `GET /api/v1/admin/platform-fee` from customer app (admin only)
- Re-fetch price-preview on booking detail (use stored booking prices)
- Hide platform fee line when it is `0` without still showing **"0.00 د.ل"** (transparency)

## PROMPT END
