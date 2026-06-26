# Flutter Backend Compatibility Fixes

Bareq production backend pagination, endpoint, and error-handling alignment for the customer Flutter app.

## Summary

- List endpoints now parse `{ items, page, pageSize, totalCount, totalPages, hasNextPage, hasPreviousPage }`.
- Customer flows no longer call admin-only `GET /api/Workers/GetWorkers` or `GET /api/Bookings/GetBookings`.
- Booking create handles HTTP **409** with Arabic conflict message; no navigation to confirmation on conflict.
- Centralized HTTP status → domain failure mapping (400, 401, 403, 404, 409, 429, 5xx).
- Infinite scroll pagination on Search and Bookings history.
- Duplicate API calls reduced (home cubit, favorites, company details, booking/maid/search screens).
- `LogInterceptor` enabled only in debug (`kDebugMode`).
- Safer JSON parsing for workers (rating, profile image) and booking create responses.

## Files changed

### Core

| File | Change |
|------|--------|
| `lib/core/network/paged_result.dart` | **New** — `PagedResult<T>` model |
| `lib/core/network/paged_list_parser.dart` | **New** — items/meta extraction (array or paginated envelope) |
| `lib/core/network/pagination_constants.dart` | **New** — default `page=1`, `pageSize=20`, max page cap |
| `lib/core/network/dio_client.dart` | `CancelToken` on all verbs; `LogInterceptor` only in debug |
| `lib/core/network/dio_failure_mapper.dart` | Status-specific failures and messages |
| `lib/core/network/api_endpoints.dart` | `getWorkersByCompany(companyId)` |
| `lib/core/error/failures.dart` | `ConflictFailure`, `RateLimitFailure`, `NotFoundFailure` |
| `lib/core/utils/failure_ui.dart` | **New** — UI messages + logout detection |
| `lib/core/auth/jwt_claims_helper.dart` | `companyId` claim helper for company staff |
| `lib/core/localization/app_localizations.dart` | `sessionExpired`, `accessDenied`, `notFound`, `serverErrorRetry`, `loadMore` |
| `lib/core/di/injection_container.dart` | New use cases; removed `GetAllBookingsUseCase` |

### Home / workers

| File | Change |
|------|--------|
| `lib/features/home/data/datasources/home_remote_datasource.dart` | Paginated `Available` + `Company/{id}`; removed `GetWorkers` usage |
| `lib/features/home/data/repositories/home_repository_impl.dart` | Paged maids, company maids, favorites resolver; no admin fallback |
| `lib/features/home/domain/repositories/home_repository.dart` | Paged + favorites contracts |
| `lib/features/home/domain/usecases/get_available_maids_page_usecase.dart` | **New** |
| `lib/features/home/domain/usecases/get_company_maids_page_usecase.dart` | **New** |
| `lib/features/home/domain/usecases/get_favorite_maids_usecase.dart` | **New** |
| `lib/features/home/data/models/maid_model.dart` | Safe rating/reviewCount/profileImage |
| `lib/features/home/presentation/cubit/home_cubit.dart` | Single workers fetch; client-side top-rated sort |
| `lib/features/home/presentation/pages/home_screen.dart` | Cubit in `State` (not `build`); no reload on `didChangeDependencies` |

### Companies

| File | Change |
|------|--------|
| `lib/features/companies/data/datasources/companies_remote_datasource.dart` | Paginated companies |
| `lib/features/companies/data/repositories/companies_repository_impl.dart` | Fetches all company pages (capped) |
| `lib/features/companies/presentation/pages/company_details_screen.dart` | `Workers/Company/{id}` instead of filtering all workers |

### Booking

| File | Change |
|------|--------|
| `lib/features/booking/data/datasources/booking_remote_datasource.dart` | Paged user/company bookings; 409 via mapper; safe create response |
| `lib/features/booking/data/repositories/booking_repository_impl.dart` | Paged APIs; removed `getAllBookings` |
| `lib/features/booking/domain/repositories/booking_repository.dart` | `getUserBookingsPage`; no admin list |
| `lib/features/booking/domain/usecases/get_my_bookings_page_usecase.dart` | **New** |
| `lib/features/booking/domain/usecases/get_all_bookings_usecase.dart` | **Deleted** |
| `lib/features/booking/presentation/pages/booking_screen.dart` | 409/401 UI; user bookings for calendar hints; no `GetBookings` |
| `lib/features/booking/presentation/pages/bookings_screen.dart` | Paginated infinite scroll |
| `lib/features/booking/presentation/pages/booking_details_screen.dart` | Company staff: `Bookings/Company/{companyId}` |

### Presentation (dedupe / pagination)

| File | Change |
|------|--------|
| `lib/features/search/presentation/pages/search_screen.dart` | Paged load + scroll; one API path |
| `lib/features/search/presentation/pages/search_results_screen.dart` | Single `getAvailableMaids` call |
| `lib/features/favorites/presentation/pages/favorites_screen.dart` | `GetFavoriteMaidsUseCase` (no full worker list ×2) |
| `lib/features/maid/presentation/pages/maid_details_screen.dart` | Single maid list fetch |
| `lib/features/booking/presentation/pages/booking_screen.dart` | Single maid fetch for booking form |

## Endpoints updated

| Area | Before | After (customer app) |
|------|--------|----------------------|
| Workers browse | `GET /api/Workers/GetWorkers` (+ 500 fallback) | `GET /api/Workers/Available?date=&page=&pageSize=` |
| Company workers | Filter all available workers | `GET /api/Workers/Company/{companyId}?page=&pageSize=` |
| User bookings | `GET /api/Bookings/User/{userId}` (raw array) | Same path + `?page=&pageSize=` + paged JSON |
| Company bookings (staff) | `GET /api/Bookings/GetBookings` (admin) | `GET /api/Bookings/Company/{companyId}?page=&pageSize=` |
| Companies list | `GET /api/Companies/GetisVerifiedCompanies` (array) | Same + pagination query params |
| Create booking | Generic errors | **409** → `ConflictFailure` (Arabic message) |

**Not used in customer app anymore:** `GET /api/Workers/GetWorkers`, `GET /api/Bookings/GetBookings`.

## Models updated

- `PagedResult<T>` — shared paginated envelope.
- `MaidModel` — nullable/missing `rating`, `reviewCount`, `profileImage`.
- `BookingModel` — already defensive; booking POST response parsing hardened in datasource.

## Pagination changes

- Default query: `page=1`, `pageSize=20`.
- **Home:** first page only (20 workers); top-rated sorted locally.
- **Search:** loads pages on scroll near bottom; guards duplicate in-flight loads.
- **Bookings history:** paged append on scroll; bottom loader.
- **Company details:** loads all pages for company workers (max 25 pages).
- **Favorites:** scans available worker pages until favorite IDs resolved (max 25 pages).
- **Companies (internal):** repository loads up to 25 pages to build verified-company filter set.

## Error handling changes

| HTTP | Failure | User-facing behavior |
|------|---------|----------------------|
| 400 | `ValidationFailure` | API/body message |
| 401 | `AuthFailure` | Logout redirect on booking create; localized session message |
| 403 | `ForbiddenFailure` | Access denied |
| 404 | `NotFoundFailure` | Not found |
| 409 | `ConflictFailure` | Arabic: «هذه العاملة غير متاحة في هذا الموعد…» — stay on booking form |
| 429 | `RateLimitFailure` | Arabic rate-limit message |
| 5xx | `ServerFailure` | Retry messaging |

## Screens to test manually

1. Login  
2. Home loading (single worker request)  
3. Search workers (scroll load more)  
4. Company details (company-scoped workers)  
5. Create booking  
6. Booking conflict **409** (same worker/date)  
7. Booking history (pagination)  
8. Favorites  
9. Logout / login again  

## Remaining backend / mobile risks

| Risk | Notes |
|------|--------|
| `GET /api/Workers/Available` returns 500 | Home/search show empty or partial data; no admin fallback (by design). |
| Worker calendar occupancy | Booking screen only marks dates from **current user’s** bookings; other customers’ approved slots rely on server **409**. |
| Company staff booking detail | Needs `companyId` in JWT; if missing, booking not found for staff. |
| Favorites completeness | Favorites resolved by paging `Available`; maids not in first N pages may not appear until backend adds favorites-by-id API. |
| Reviews list | `POST /api/Reviews` only; no paginated reviews list wired in this pass. |
| HTTP base URL | Still `http://102.203.200.55:5545` — production should use HTTPS. |
| Work types / languages | May still return raw arrays; parser accepts both shapes. |

## Second pass (CleaningHouse API spec alignment)

| Item | Status |
|------|--------|
| `PagedResult<T>` in **data layer** (`lib/core/data/models/`) | Done — network re-exports for compatibility |
| `maxPageSize` = 50, `paginationQuery` clamps | Done |
| ProblemDetails 500 (`detail` then `title`) | Done — `dio_failure_mapper.dart` |
| `GET UserLocations/GetMyLocations?page&pageSize` | Done — paginated datasource + screen scroll |
| Create location `{ locationName, lat, lng }` | Already correct |
| Removed `GetBookings` / `GetWorkers` from `ApiEndpoints` | Done |
| Public paths: `Workers/Available` not `GetWorkers` | Done — `public_api_paths.dart` |
| Cities list paged parse | Done — `extractPagedItems` in auth datasource |
| Profile PUT APIs + 401 on change password | Already wired; 401 → login added |

## Analyze

`flutter analyze` — **0 errors** after changes (pre-existing infos/warnings remain).
