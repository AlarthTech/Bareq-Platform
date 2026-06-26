# Bareq Flutter App — Full Technical Review

**Project:** `sitt_app` (Bareq customer mobile app)  
**Review date:** May 2026  
**Scope:** Entire `lib/` codebase, Android/iOS config, networking, state, performance, production readiness  
**Mode:** Audit only — **no code was modified**

> **Update (post-fix):** A backend compatibility pass was completed after this audit.  
> See **`FLUTTER_POST_FIX_TECHNICAL_REPORT.md`** for revised readiness grades and fix status.  
> Implementation details: **`FLUTTER_BACKEND_COMPATIBILITY_FIXES.md`**.

---

## 1. Executive Summary

Bareq is a **feature-first Flutter app** with a **partial Clean Architecture** implementation. Strongest areas: **auth**, **user_locations**, and **legal** (domain repositories with `Either<Failure, T>`, datasources, use cases, DI registration). Weakest areas: **home**, **companies**, **search**, **booking**, and **maid** flows where presentation calls use cases via **GetIt (`sl<>`) directly**, repositories **swallow errors as empty lists**, and **network traffic is duplicated** across screens.

### Overall readiness: **Not production-ready** for scale or store release without remediation.

| Area | Grade | Summary |
|------|-------|---------|
| Architecture | C+ | 6 features with full layers; 5 thin/presentation-only; layer violations exist |
| Networking | D+ | HTTP-only API, no refresh token, logging in release, inconsistent error mapping |
| State management | C | Only 3 cubits; most screens use `setState` + service locator |
| Performance | C- | No image cache, no pagination, heavy screens, duplicate API on home/search |
| Offline / errors | C- | Partial handling; silent failures mask outages |
| Caching | D | Only SharedPreferences/secure storage; no reference-data cache |
| UI stability | B- | Recent RTL/login polish; overflow risks on small devices remain |
| Production | D | `com.example.*` IDs, debug signing, no Crashlytics/CI, minimal tests |

**Top 3 risks before launch:**
1. **Cleartext HTTP API** + **PII logged in release** (`LogInterceptor`).
2. **Duplicate full worker/company fetches** on home, search, favorites, booking (2× pipeline per screen open).
3. **Store blockers:** example bundle IDs, Android release signed with debug keys, no crash monitoring.

---

## 2. Critical Crash Risks

### CR-01 — `Positioned` used outside direct `Stack` child (login butterfly)

| Field | Detail |
|-------|--------|
| **File** | `lib/features/auth/presentation/widgets/login_floating_butterfly.dart` (historical); fixed in login `Stack` by wrapping with `Positioned` parent — **verify all overlays** |
| **Problem** | Returning `Positioned` from a widget whose parent is `IgnorePointer` causes repeated **"Incorrect use of ParentDataWidget"** runtime errors |
| **Why dangerous** | Floods console, breaks layout pass, can blank screens in debug/profile mode |
| **Solution** | Always use internal `Stack` + `Positioned`, or parent `Positioned.fill` with bounded child `Stack` |
| **Priority** | **Critical** (if regression reintroduced) |
| **Difficulty** | Low |

### CR-02 — Unsafe JSON / null assumptions in data models

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/data/models/maid_model.dart` (`fromJson`, lines 28–80+) |
| **Problem** | Casts like `json['fullName'] as String?` without full schema validation; missing fields default to `0.0` rating, empty specialties |
| **Why dangerous** | API shape changes → runtime cast exceptions or **silent wrong UI** (all maids 0★) |
| **Solution** | Defensive parsing, `try/catch` per field, explicit `ServerFailure` on malformed payloads |
| **Priority** | **Critical** |
| **Difficulty** | Medium |

### CR-03 — `company_details_screen` mock fallback can show wrong company

| Field | Detail |
|-------|--------|
| **File** | `lib/features/companies/presentation/pages/company_details_screen.dart` (lines 60–98) |
| **Problem** | On API failure, `_loadCompanyFromMock()` loads full company list and `firstWhere(..., orElse: () => companies.first)` |
| **Why dangerous** | User may see **wrong company** after error — trust/legal risk |
| **Solution** | Show error state with retry; never substitute arbitrary company |
| **Priority** | **Critical** |
| **Difficulty** | Low |

### CR-04 — iOS App Transport Security (HTTP API)

| Field | Detail |
|-------|--------|
| **File** | `lib/core/network/api_endpoints.dart` (line 7: `http://102.203.200.55:5545`); `ios/Runner/Info.plist` (no `NSAppTransportSecurity` exception) |
| **Problem** | API is plain HTTP; Android allows via `network_security_config.xml`; **iOS may block or behave inconsistently** without ATS exceptions |
| **Why dangerous** | **Total API failure on iOS production devices** |
| **Solution** | Move API to HTTPS; add ATS exception only as temporary measure |
| **Priority** | **Critical** |
| **Difficulty** | Medium (infra) |

### CR-05 — `delete()` path throws generic `Exception` not `Failure`

| Field | Detail |
|-------|--------|
| **File** | `lib/core/network/dio_client.dart` (lines 109–139) |
| **Problem** | `delete` uses `_handleError` → `Exception`, unlike `get/post` which rethrow `DioException` |
| **Why dangerous** | Uncaught exceptions in delete flows (account delete, locations) → **app crash** if not wrapped |
| **Solution** | Align `delete` with other verbs; use `mapDioExceptionToFailure` |
| **Priority** | **High** |
| **Difficulty** | Low |

---

## 3. Performance Problems

### PERF-01 — No network image caching

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/home/presentation/widgets/maid_card.dart` (~194); `lib/features/maid/presentation/pages/maid_details_screen.dart`; `lib/features/booking/presentation/widgets/booking_card.dart`; `lib/features/booking/presentation/pages/booking_details_screen.dart` |
| **Problem** | Raw `Image.network` everywhere; **no** `cached_network_image` in `pubspec.yaml` |
| **Why dangerous** | Re-downloads avatars on every scroll/visit → jank, data usage, memory spikes decoding full-res images |
| **Solution** | Add `cached_network_image` with `memCacheWidth`/`memCacheHeight` sized to display |
| **Priority** | **High** |
| **Difficulty** | Medium |

### PERF-02 — `HomeCubit` loads both maid use cases in parallel (double pipeline)

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/presentation/cubit/home_cubit.dart` (lines 35–38); `lib/features/home/data/repositories/home_repository_impl.dart` (lines 107–112) |
| **Problem** | `Future.wait([getAvailableMaids, getTopRatedMaids])` — top-rated **re-runs entire** `getAvailableMaidsToday` + sort |
| **Why dangerous** | **2×** `GetisVerifiedCompanies` + **2×** workers per home load; scales poorly with users |
| **Solution** | Single `getHomeMaids(date)` use case; derive top-rated in memory from one response |
| **Priority** | **High** |
| **Difficulty** | Medium |

### PERF-03 — `HomeScreen` recreates `BlocProvider` in `build()`

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/presentation/pages/home_screen.dart` (lines 39–51) |
| **Problem** | `BlocProvider` + `..loadHomeData()` created in `build()` |
| **Why dangerous** | Parent rebuild → **new cubit** → full API reload, flicker, battery drain |
| **Solution** | Provide cubit at route/shell level (`BlocProvider.value` or `MultiBlocProvider` above tab shell) |
| **Priority** | **High** |
| **Difficulty** | Medium |

### PERF-04 — `didChangeDependencies` retriggers home + user load

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/presentation/pages/home_screen.dart` (`didChangeDependencies`, ~91–98; `_loadCurrentUser` ~101–117) |
| **Problem** | `Future.microtask(_loadCurrentUser)` on every dependency change; success calls `loadHomeData` again |
| **Why dangerous** | Theme/locale/inherited widget updates → **duplicate network storms** |
| **Solution** | Load once in `initState`; guard with `_didLoad` flag |
| **Priority** | **High** |
| **Difficulty** | Low |

### PERF-05 — Monolithic screens (rebuild cost)

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/booking/presentation/pages/booking_screen.dart` (**~2174 lines**); `lib/features/home/presentation/pages/home_screen.dart` (**~1651 lines**); `lib/features/maid/presentation/pages/maid_details_screen.dart` (large) |
| **Problem** | Single `StatefulWidget` holds booking logic, maps, calendars, API calls |
| **Why dangerous** | Any `setState` rebuilds huge subtree; hard to optimize with `const` |
| **Solution** | Split into feature widgets + dedicated cubit; localize `setState` |
| **Priority** | **Medium** |
| **Difficulty** | High |

### PERF-06 — `MaidCard` allocates multiple `AnimationController`s per cell

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/presentation/widgets/maid_card.dart` (lines 29–91) |
| **Problem** | Up to 3 controllers + `FavoritesProvider` listener per card |
| **Why dangerous** | Horizontal lists with many maids → CPU/battery cost while scrolling |
| **Solution** | Static grid variant without pulse; defer animations until visible (`visibility_detector`) |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### PERF-07 — Non-virtualized booking list

| Field | Detail |
|-------|--------|
| **File** | `lib/features/booking/presentation/pages/bookings_screen.dart` (~306–315) |
| **Problem** | `ListView` + `.map().toList()` builds **all** booking cards at once |
| **Why dangerous** | Large booking history → memory pressure, first-frame jank |
| **Solution** | `ListView.builder` with item count |
| **Priority** | **Medium** |
| **Difficulty** | Low |

### PERF-08 — Companies screen nested non-lazy grid

| Field | Detail |
|-------|--------|
| **File** | `lib/features/companies/presentation/pages/companies_screen.dart` (~522–567) |
| **Problem** | `ListView` containing `GridView.builder(shrinkWrap: true, NeverScrollableScrollPhysics)` |
| **Why dangerous** | Builds **entire grid** in one frame |
| **Solution** | `CustomScrollView` + slivers (`SliverGrid`) |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### PERF-09 — Artificial delays on network paths

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/search/presentation/pages/search_screen.dart` (line 113); `lib/features/home/data/repositories/home_repository_impl.dart` (line 118, mock categories) |
| **Problem** | `Future.delayed(500ms)` before/around loads |
| **Why dangerous** | Adds latency; masks real performance; stays in production path for search |
| **Solution** | Remove delays; use real loading indicators only |
| **Priority** | **Medium** |
| **Difficulty** | Low |

### PERF-10 — Google Fonts on every rebuild

| Field | Detail |
|-------|--------|
| **File** | `lib/app.dart` (builder wraps `GoogleFonts.almarai`); `lib/core/theme/light_theme.dart` |
| **Problem** | Font resolution in `MaterialApp.builder` tied to `LanguageProvider` |
| **Why dangerous** | Extra work on locale toggle; first-run font download latency |
| **Solution** | Bundle Almarai in assets (`pubspec` fonts) for offline/stable startup |
| **Priority** | **Low** |
| **Difficulty** | Medium |

### PERF-11 — Startup blocks on auth restore

| Field | Detail |
|-------|--------|
| **Files** | `lib/main.dart` (await `di.init()`); `lib/core/di/injection_container.dart` (lines 232–236); `lib/features/auth/presentation/pages/splash_screen.dart` (2s delay + re-auth) |
| **Problem** | `AuthSessionNotifier.restore` + `CheckAuthentication` before `runApp`; splash adds **2s** + duplicate check |
| **Why dangerous** | Perceived slow cold start; redundant I/O |
| **Solution** | Show UI immediately; restore session asynchronously; remove fixed splash delay |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

---

## 4. API Usage Problems

### API-01 — Duplicate worker + company fetch pattern (app-wide)

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/search/presentation/pages/search_screen.dart` (lines 116–125); `lib/features/favorites/presentation/pages/favorites_screen.dart`; `lib/features/booking/presentation/pages/booking_screen.dart`; `lib/features/companies/presentation/pages/company_details_screen.dart`; `lib/features/maid/presentation/pages/maid_details_screen.dart` |
| **Problem** | Pattern: `getAvailableMaidsUseCase` + `getTopRatedMaidsUseCase` → **2× full home repository pipeline** |
| **Why dangerous** | Under load, **4 HTTP calls per screen** (2× companies, 2× workers); server and client bottleneck |
| **Solution** | `GetHomeWorkersUseCase(date)` returning `{all, topRated}` from single fetch |
| **Priority** | **Critical** |
| **Difficulty** | Medium |

### API-02 — `Workers/Available` 500 with silent fallback

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/data/repositories/home_repository_impl.dart` (lines 26–38, 56) |
| **Problem** | On 500 from date endpoint, falls back to `getWorkers()` without user-visible distinction |
| **Why dangerous** | Wrong availability semantics; hides server bugs; user books unavailable workers |
| **Solution** | Surface degraded state in UI; log to monitoring; fix backend |
| **Priority** | **High** |
| **Difficulty** | Medium |

### API-03 — No pagination on workers/bookings/companies

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/home/data/datasources/home_remote_datasource.dart`; `lib/features/booking/data/datasources/booking_remote_datasource.dart`; `lib/features/companies/data/datasources/companies_remote_datasource.dart` |
| **Problem** | All list endpoints fetched in full |
| **Why dangerous** | Memory and parse time grow linearly; timeouts as data grows |
| **Solution** | Server pagination + `page`/`limit` in repositories; infinite scroll |
| **Priority** | **High** |
| **Difficulty** | High (requires backend) |

### API-04 — Search is client-side only; no debounce needed today, but reload on date change

| Field | Detail |
|-------|--------|
| **File** | `lib/features/search/presentation/pages/search_screen.dart` (`_onSearchChanged` → `_applyFilters`; date change → `_loadMaids`) |
| **Problem** | Text filter is local (OK); changing booking date triggers **full network reload** without debounce |
| **Why dangerous** | Rapid date picks → request pile-up |
| **Solution** | Debounce date reload 300–500ms; cancel in-flight request with `CancelToken` |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### API-05 — No request cancellation

| Field | Detail |
|-------|--------|
| **File** | `lib/core/network/dio_client.dart` (all methods) |
| **Problem** | No `CancelToken` support; navigating away does not cancel in-flight Dio calls |
| **Why dangerous** | Stale responses applied after leave screen → wrong state / `setState` after dispose |
| **Solution** | Pass `CancelToken` from cubits; cancel in `dispose` |
| **Priority** | **High** |
| **Difficulty** | Medium |

### API-06 — `company_details` redundant fetches

| Field | Detail |
|-------|--------|
| **File** | `lib/features/companies/presentation/pages/company_details_screen.dart` |
| **Problem** | `GetCompanyById` failure → `GetCompanies` full list; then dual maid use cases |
| **Why dangerous** | Worst-case **5+ list calls** opening one company |
| **Solution** | Single orchestrating use case with cached company + maids |
| **Priority** | **High** |
| **Difficulty** | Medium |

### API-07 — `booking_details` polling every 30s

| Field | Detail |
|-------|--------|
| **File** | `lib/features/booking/presentation/pages/booking_details_screen.dart` (lines 50–67) |
| **Problem** | `Timer.periodic(30s)` refetches booking |
| **Why dangerous** | Battery/network use if screen left open; no backoff; not cancelled if widget tree edge cases |
| **Solution** | WebSocket/push or exponential backoff; stop poll on terminal status (partially may exist — verify) |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### API-08 — Favorites loads entire catalog to resolve IDs

| Field | Detail |
|-------|--------|
| **File** | `lib/features/favorites/presentation/pages/favorites_screen.dart` |
| **Problem** | Fetches all available + top-rated maids to filter local favorite IDs |
| **Why dangerous** | O(all workers) per favorites tab visit |
| **Solution** | `GET /workers?ids=` batch endpoint or cache worker catalog |
| **Priority** | **High** |
| **Difficulty** | High |

---

## 5. State Management Problems

### SM-01 — Presentation bypasses cubits (dominant pattern)

| Field | Detail |
|-------|--------|
| **Files** | 20+ files importing `lib/core/di/injection_container.dart` — e.g. `booking_screen.dart` (11 `sl<>` refs), `search_screen.dart`, `companies_screen.dart`, `profile_screen.dart` |
| **Problem** | Business logic and API calls inside `StatefulWidget` methods |
| **Why dangerous** | Untestable UI, duplicated flows, inconsistent loading/error UX |
| **Solution** | Feature cubits for booking/search/companies/profile; register in DI |
| **Priority** | **High** |
| **Difficulty** | High |

### SM-02 — Only 3 cubits in entire app

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/home/presentation/cubit/home_cubit.dart`; `lib/features/auth/presentation/cubit/login_cubit.dart`; `registration_cubit.dart` |
| **Problem** | `flutter_bloc` declared in `pubspec` but barely used |
| **Why dangerous** | No single source of truth for async state on critical flows |
| **Solution** | Expand cubit coverage or adopt consistent alternative (Riverpod) |
| **Priority** | **High** |
| **Difficulty** | High |

### SM-03 — Inconsistent error handling (Either vs empty list vs string)

| Field | Detail |
|-------|--------|
| **Files** | `home_repository_impl.dart` (returns `[]`); `companies_repository_impl.dart`; `home_cubit.dart` (`HomeError(e.toString())`); auth uses `Either` |
| **Problem** | Same failure appears as empty UI, snackbar, or error panel depending on screen |
| **Why dangerous** | Users cannot distinguish **no data** vs **offline** |
| **Solution** | Standardize on `Either<Failure, T>` through domain; map to `UiState` sealed class |
| **Priority** | **High** |
| **Difficulty** | High |

### SM-04 — `HomeCubit` depends on `SharedPreferences` (infra in presentation)

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/presentation/cubit/home_cubit.dart` (lines 2, 18, 68–79) |
| **Problem** | City filter persistence inside cubit |
| **Why dangerous** | Violates clean boundaries; hard to test |
| **Solution** | `HomeLocalDataSource` or pass selected city from repository/use case |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### SM-05 — `FavoritesProvider` global singleton outside DI

| Field | Detail |
|-------|--------|
| **File** | `lib/core/favorites/favorites_provider.dart` |
| **Problem** | `FavoritesProvider.instance` + direct `SharedPreferences` |
| **Why dangerous** | Hidden global state; second `SharedPreferences` instance; not lifecycle-aware |
| **Solution** | `FavoritesRepository` + cubit; register in `injection_container.dart` |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### SM-06 — Missing loading/empty/error on several screens

| Field | Detail |
|-------|--------|
| **Files** | `companies_screen.dart` (partial); `company_home_screen.dart`; `notifications_settings_screen.dart` (static); parts of `booking_screen.dart` |
| **Problem** | Not all screens use `AppEmptyState` / retry pattern consistently |
| **Why dangerous** | Blank screens on failure; poor UX for Libyan non-technical users |
| **Solution** | Shared `AsyncView` widget: loading / empty / error / retry |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### SM-07 — `GetServiceCategoriesUseCase` not registered

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/home/domain/usecases/get_service_categories_usecase.dart`; `lib/core/di/injection_container.dart` |
| **Problem** | Use case exists; returns mock from repository; **not in DI** |
| **Why dangerous** | Dead code / future integration footgun |
| **Solution** | Register or remove; wire real API when ready |
| **Priority** | **Low** |
| **Difficulty** | Low |

---

## 6. Architecture Problems

### ARCH-01 — Data model extends domain entity

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/home/data/models/maid_model.dart` (line 5); `lib/features/auth/data/models/user_model.dart` |
| **Problem** | `MaidModel extends Maid` — JSON concerns on entity type |
| **Why dangerous** | Domain layer polluted; serialization leaks upward |
| **Solution** | `toEntity()` / `fromJson` factory on model only |
| **Priority** | **High** |
| **Difficulty** | Medium |

### ARCH-02 — Presentation imports data model

| Field | Detail |
|-------|--------|
| **File** | `lib/features/profile/presentation/pages/settings/edit_profile_screen.dart` (lines 7–8, 25) |
| **Problem** | `UserModel? _user` in UI |
| **Why dangerous** | **Direct layer violation**; breaks Clean Architecture |
| **Solution** | Use `User` entity only in presentation |
| **Priority** | **High** |
| **Difficulty** | Low |

### ARCH-03 — Core widget calls use case via GetIt

| Field | Detail |
|-------|--------|
| **File** | `lib/core/widgets/common/app_top_bar.dart` (lines 6–10, 101–102) |
| **Problem** | `GetCurrentUserUseCase` loaded in top bar |
| **Why dangerous** | Core UI coupled to auth feature + DI |
| **Solution** | Pass `User?` from parent or `InheritedWidget` / session notifier |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### ARCH-04 — Home data layer depends on companies repository

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/data/repositories/home_repository_impl.dart` (lines 11–12, 44–54) |
| **Problem** | Cross-feature repository injection in data layer |
| **Why dangerous** | Tight coupling; circular risk as features grow |
| **Solution** | `GetVerifiedCompanyIdsUseCase` in domain orchestration layer |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### ARCH-05 — `AppStrings` in data repository (mock categories)

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/data/repositories/home_repository_impl.dart` (lines 9, 116–141) |
| **Problem** | Mock `getServiceCategories` uses UI string constants |
| **Why dangerous** | Data layer depends on presentation copy |
| **Solution** | API-driven categories or domain constants |
| **Priority** | **Medium** |
| **Difficulty** | Low |

### ARCH-06 — Thin / empty features

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/maid/` (`.gitkeep` in data/domain); `lib/features/search/` (no data/domain); `lib/features/profile/` (presentation only); `lib/features/favorites/`; `lib/features/company/` vs `companies/` |
| **Problem** | Incomplete boundaries; duplicated naming |
| **Why dangerous** | Features become dumping grounds for logic |
| **Solution** | Merge or complete `maid` + `search` layers; consolidate company vs companies |
| **Priority** | **Medium** |
| **Difficulty** | High |

### ARCH-07 — `booking_screen` as god widget

| Field | Detail |
|-------|--------|
| **File** | `lib/features/booking/presentation/pages/booking_screen.dart` |
| **Problem** | 11+ use cases, maps, auth, company fee store in one file |
| **Why dangerous** | Unmaintainable; high regression risk |
| **Solution** | `BookingCubit` + step widgets (`date_step`, `location_step`, `confirm_step`) |
| **Priority** | **High** |
| **Difficulty** | High |

---

## 7. Caching Recommendations

| Data | Current | Recommendation | Priority | Difficulty |
|------|---------|----------------|----------|------------|
| **Cities** | Fetched on every `HomeCubit.loadHomeData` | Cache in `SharedPreferences` / Hive with TTL 24h; invalidate on pull-to-refresh | High | Medium |
| **Languages** | `GetLanguagesUseCase` per search open | In-memory singleton cache after first load | High | Low |
| **Verified companies** | Fetched on every worker load | Cache company IDs list 15–60 min; version header from API | Critical | Medium |
| **Workers catalog** | Full fetch per screen | Single session cache keyed by `date`; stale-while-revalidate | Critical | High |
| **Work types** | Per booking | Cache by `workerId` + `companyId` in memory | Medium | Medium |
| **User profile** | Local after login | Already in `AuthLocalDataSource` — ensure **not** refetched on every `didChangeDependencies` | High | Low |
| **Legal documents** | Asset bundle | OK — no network |
| **Favorites** | `SharedPreferences` | OK — keep; move behind repository | Medium | Medium |

### CACHE-01 — No Hive/Isar (optional)

| Field | Detail |
|-------|--------|
| **File** | `pubspec.yaml` |
| **Problem** | Only `shared_preferences` + `flutter_secure_storage` |
| **Why dangerous** | Large lists re-fetched; no structured offline cache |
| **Solution** | Hive/Isar for worker list cache and bookings offline read model |
| **Priority** | **Medium** |
| **Difficulty** | High |

---

## 8. Networking Improvements

### NET-01 — `LogInterceptor` always enabled

| Field | Detail |
|-------|--------|
| **File** | `lib/core/network/dio_client.dart` (lines 30–32) |
| **Problem** | Logs full bodies in **release** builds |
| **Why dangerous** | **Passwords, JWT, PII** in device logs; compliance risk |
| **Solution** | `if (kDebugMode)` guard or flavor-based interceptor |
| **Priority** | **Critical** |
| **Difficulty** | Low |

### NET-02 — No refresh token / retry

| Field | Detail |
|-------|--------|
| **Files** | `lib/core/network/auth_interceptor.dart`; `lib/features/auth/data/repositories/auth_repository_impl.dart` |
| **Problem** | 401 → clear session → login; `ApiEndpoints.logout` unused |
| **Why dangerous** | Poor UX on token expiry; no silent refresh |
| **Solution** | Implement refresh flow or document intentional re-login; call server logout on sign-out |
| **Priority** | **High** |
| **Difficulty** | High |

### NET-03 — Hardcoded HTTP base URL

| Field | Detail |
|-------|--------|
| **File** | `lib/core/network/api_endpoints.dart` (line 7) |
| **Problem** | Single production IP; no dev/staging/prod flavors |
| **Why dangerous** | Cannot safely test; MITM; store rejection |
| **Solution** | `--dart-define=API_BASE_URL` + flavors; HTTPS only |
| **Priority** | **Critical** |
| **Difficulty** | Medium |

### NET-04 — Duplicate error extraction

| Field | Detail |
|-------|--------|
| **Files** | `lib/core/network/dio_failure_mapper.dart`; `lib/features/auth/data/datasources/auth_remote_datasource.dart` (`_extractServerErrorMessage`) |
| **Problem** | Two parsing strategies |
| **Why dangerous** | Inconsistent user-facing errors |
| **Solution** | All datasources use `mapDioExceptionToFailure` only |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### NET-05 — Timeouts 30s only; no send timeout

| Field | Detail |
|-------|--------|
| **File** | `lib/core/network/dio_client.dart` (lines 15–16) |
| **Problem** | Long hang on bad networks; upload-heavy booking may need `sendTimeout` |
| **Why dangerous** | UI frozen perceived; poor mobile UX |
| **Solution** | 15s connect/receive; retry with backoff for idempotent GETs |
| **Priority** | **Medium** |
| **Difficulty** | Low |

### NET-06 — No connectivity check before calls

| Field | Detail |
|-------|--------|
| **File** | App-wide |
| **Problem** | No `connectivity_plus` / offline banner |
| **Why dangerous** | Generic errors; user confusion |
| **Solution** | Central `NetworkInfo` wrapper; snackbar when offline |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

---

## 9. UI/UX Stability Problems

### UX-01 — RTL navigation chevrons (partially fixed)

| Field | Detail |
|-------|--------|
| **File** | `lib/core/widgets/common/bareq_nav_chevron.dart` |
| **Problem** | Not adopted app-wide yet; some screens may still hardcode chevrons |
| **Why dangerous** | Arabic users see wrong affordances |
| **Solution** | Enforce `BareqNavChevron` via lint/custom rule |
| **Priority** | **Medium** |
| **Difficulty** | Low |

### UX-02 — Layout overflow risk on small devices

| Field | Detail |
|-------|--------|
| **Files** | `lib/features/home/presentation/widgets/maid_card.dart` (grid); `lib/features/auth/presentation/pages/login_screen.dart` (dense form) |
| **Problem** | Tall maid cards (`childAspectRatio: 0.62`); login may scroll on iPhone SE |
| **Why dangerous** | Yellow/black overflow stripes in production |
| **Solution** | Test on SE; `FittedBox` / reduced padding; `LayoutBuilder` breakpoints |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### UX-03 — `Positioned` / overlay widgets

| Field | Detail |
|-------|--------|
| **File** | `lib/features/auth/presentation/widgets/login_floating_butterfly.dart` |
| **Problem** | Must stay within correct Stack hierarchy |
| **Why dangerous** | ParentData crashes (seen in development) |
| **Solution** | Document pattern; widget test login screen |
| **Priority** | **High** |
| **Difficulty** | Low |

### UX-04 — City filter client-side only on home

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/presentation/cubit/home_cubit.dart` + `home_screen.dart` |
| **Problem** | City selection filters in UI but maids loaded for all — filter may not match API city |
| **Why dangerous** | User thinks city applied at API level; wrong results |
| **Solution** | Pass city to worker API when backend supports; document behavior |
| **Priority** | **Medium** |
| **Difficulty** | Medium |

### UX-05 — Workers show `rating: 0.0` when API omits rating

| Field | Detail |
|-------|--------|
| **File** | `lib/features/home/data/models/maid_model.dart` (line 75) |
| **Problem** | Default 0.0 for Workers API format |
| **Why dangerous** | Misleading trust UI for Libyan users |
| **Solution** | Hide rating chip when absent; show "جديد" or N/A |
| **Priority** | **Medium** |
| **Difficulty** | Low |

---

## 10. Production Readiness Checklist

| Item | Status | Notes |
|------|--------|-------|
| HTTPS API | ❌ | `http://102.203.200.55:5545` |
| iOS ATS configured | ❌ | No exception in `Info.plist` |
| Android cleartext | ⚠️ | Explicitly allowed for IP in `network_security_config.xml` |
| Bundle ID | ❌ | `com.example.sitt_app` / `com.example.sittApp` |
| Android release signing | ❌ | Debug keys in `android/app/build.gradle.kts` (lines 34–38) |
| Firebase / FCM | ❌ | Not in `pubspec.yaml` |
| Crashlytics / Sentry | ❌ | No crash reporting |
| Analytics | ❌ | Not integrated |
| Environment flavors (dev/staging/prod) | ❌ | Single hardcoded base URL |
| CI/CD (GitHub Actions) | ❌ | No `.github/workflows` |
| Unit / integration tests | ❌ | Only default `test/widget_test.dart` (smoke, needs DI mock) |
| ProGuard / R8 rules | ⚠️ | Default Flutter |
| Obfuscation | ❌ | Not configured |
| LogInterceptor disabled in release | ❌ | |
| Privacy policy / legal in app | ✅ | Legal feature + assets |
| Secure token storage | ✅ | `flutter_secure_storage` |
| Localization AR/EN | ✅ | `app_localizations.dart` + Almarai |
| App display name | ✅ | "Bareq" on Android/iOS |
| Push notifications UI | ⚠️ | Notifications screen info-only |
| Deep linking / routes | ✅ | `go_router` + `AuthSessionNotifier` |
| Offline mode | ❌ | No offline-first strategy |

**Recommended additions:** Firebase Crashlytics, Firebase Analytics (or Mixpanel), environment `--dart-define`, fastlane CI, integration tests for auth + booking happy path.

---

## 11. Scalability Recommendations

1. **API layer:** Paginate workers/bookings; add `ETag`/`If-None-Match` for catalog; batch endpoints for favorites-by-ids.
2. **Client cache:** Session-level worker cache + TTL; dedupe company verification fetch across features.
3. **State:** Introduce cubits/blocs per feature; single orchestration use case per screen.
4. **Images:** CDN URLs with resize params + disk cache.
5. **Backend load:** Rate-limit client retries; exponential backoff; cancel stale requests.
6. **Multi-role:** `AuthSessionNotifier` already routes admin/company/customer — ensure company/admin flows do not pull customer-sized catalogs.
7. **Observability:** Correlate `X-Request-Id` header in Dio; log failures to Crashlytics non-fatally.
8. **Feature flags:** Remote config for risky endpoints (`Workers/Available`) fallback behavior.

---

## 12. Step-by-Step Improvement Plan

### Phase 0 — Stop the bleeding (1–3 days) — **Critical**

| Step | Action | Files / area |
|------|--------|----------------|
| 0.1 | Gate `LogInterceptor` with `kDebugMode` | `dio_client.dart` |
| 0.2 | Fix `Positioned`/Stack patterns (login butterfly) | `login_floating_butterfly.dart`, `login_screen.dart` |
| 0.3 | Remove `company_details` wrong-company fallback | `company_details_screen.dart` |
| 0.4 | Plan HTTPS migration + iOS ATS | `api_endpoints.dart`, `Info.plist` |
| 0.5 | Change Android/iOS bundle IDs | `build.gradle.kts`, `project.pbxproj` |

### Phase 1 — Network & data correctness (1–2 weeks) — **High**

| Step | Action |
|------|--------|
| 1.1 | Merge `getTopRatedMaids` into single home fetch |
| 1.2 | Standardize repositories on `Either<Failure, T>`; remove `[]` on error |
| 1.3 | Add `CancelToken` to Dio + screen dispose |
| 1.4 | Unify `mapDioExceptionToFailure` in all datasources |
| 1.5 | Fix `HomeScreen` BlocProvider placement + `didChangeDependencies` guard |
| 1.6 | Remove artificial `Future.delayed` in search/home |

### Phase 2 — Performance & caching (2–3 weeks) — **High**

| Step | Action |
|------|--------|
| 2.1 | Add `cached_network_image` + size constraints |
| 2.2 | Cache cities/languages/companies in memory + disk TTL |
| 2.3 | Convert bookings list to `ListView.builder` |
| 2.4 | Refactor companies screen to sliver grid |
| 2.5 | Split `booking_screen` / `home_screen` into smaller widgets |

### Phase 3 — Architecture & state (3–4 weeks) — **Medium–High**

| Step | Action |
|------|--------|
| 3.1 | Add `BookingCubit`, `SearchCubit`, `CompaniesCubit`, `ProfileCubit` |
| 3.2 | Remove `UserModel` from `edit_profile_screen` |
| 3.3 | `MaidModel.toEntity()` — stop extending entity |
| 3.4 | Move favorites/fees into DI + repository |
| 3.5 | Complete or merge thin features (`maid`, `search`, `company`) |

### Phase 4 — Production & scale (2–4 weeks) — **High**

| Step | Action |
|------|--------|
| 4.1 | Release signing + Play/App Store assets |
| 4.2 | Crashlytics + basic analytics |
| 4.3 | Flavors: dev/staging/prod API URLs |
| 4.4 | CI: `flutter analyze`, `flutter test`, build APK/IPA |
| 4.5 | Integration tests: login, home load, booking create |
| 4.6 | Server pagination (coordinate with backend) |

### Phase 5 — Polish & monitor (ongoing) — **Medium**

| Step | Action |
|------|--------|
| 5.1 | Shared `AsyncView` for loading/empty/error/retry |
| 5.2 | RTL audit with `BareqNavChevron` everywhere |
| 5.3 | Performance profiling (DevTools) on iPhone SE + low-end Android |
| 5.4 | Load testing client against staging API |

---

## Appendix A — Feature architecture map

```
lib/
├── core/           # DI, network, theme, routing, favorites (should be feature)
├── features/
│   ├── auth/       ✅ data + domain + presentation (cubit)
│   ├── home/       ⚠️ data + domain + cubit (weak Either)
│   ├── booking/    ⚠️ data + domain; presentation god-file
│   ├── companies/  ⚠️ data + domain; presentation setState
│   ├── search/     ❌ presentation only
│   ├── maid/       ❌ presentation only (uses home use cases)
│   ├── profile/    ❌ presentation (uses auth)
│   ├── favorites/  ❌ presentation + core singleton
│   ├── user_locations/ ✅ full stack + Either
│   ├── legal/      ✅ assets + Either
│   └── company/    ❌ shell UI only
```

## Appendix B — Key dependencies (`pubspec.yaml`)

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | Underused state management |
| `dio` | HTTP |
| `get_it` | DI |
| `go_router` | Navigation |
| `shared_preferences` | Prefs + favorites |
| `flutter_secure_storage` | JWT |
| `google_fonts` | Almarai (runtime) |
| `flutter_animate` | Widespread animations |

**Not present:** `cached_network_image`, `firebase_*`, `connectivity_plus`, `hive`/`isr`, `freezed`/`json_serializable` code gen.

---

*End of report. No source files were modified during this audit.*
