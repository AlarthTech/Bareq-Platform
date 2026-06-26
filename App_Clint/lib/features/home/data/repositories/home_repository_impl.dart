import '../../domain/entities/maid.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/language.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/utils/worker_availability_label_builder.dart';
import '../models/worker_card_model.dart';
import '../models/service_category_model.dart';
import '../models/language_model.dart';
import '../datasources/home_remote_datasource.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/paged_result.dart';
import '../../../../core/network/pagination_constants.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/domain/repositories/companies_repository.dart';
import '../../../ratings/domain/entities/rating_summary.dart';
import '../../../ratings/domain/repositories/rating_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.companiesRepository,
    required this.ratingRepository,
  });

  final HomeRemoteDataSource remoteDataSource;
  final CompaniesRepository companiesRepository;
  final RatingRepository ratingRepository;

  List<Maid>? _topRatedFallbackCache;
  Set<String>? _todayAvailableWorkerIdsCache;

  Future<({Set<int> verifiedIds, Map<String, Company> byId})>
      _verifiedCompaniesContext() async {
    final verifiedCompanies = await companiesRepository.getAllCompanies();
    final companyById = <String, Company>{};
    final verifiedCompanyIds = <int>{};
    for (final company in verifiedCompanies) {
      final id = int.tryParse(company.id) ?? 0;
      if (id > 0) {
        verifiedCompanyIds.add(id);
        companyById[company.id] = company;
      }
    }
    return (verifiedIds: verifiedCompanyIds, byId: companyById);
  }

  List<Maid> _mapWorkerCards(
    List<Map<String, dynamic>> items,
    Set<int> verifiedCompanyIds,
    Map<String, Company> companyById,
  ) {
    return items
        .map((json) {
          final companyIdRaw = json['companyId'];
          final companyId = companyIdRaw is int
              ? companyIdRaw
              : int.tryParse(companyIdRaw?.toString() ?? '') ?? 0;
          if (companyId <= 0 || !verifiedCompanyIds.contains(companyId)) {
            return null;
          }
          final enriched = Map<String, dynamic>.from(json);
          final company = companyById[companyId.toString()];
          if (company != null) {
            final city = company.cityName;
            final locationLabel = (city != null && city.isNotEmpty)
                ? city
                : company.location;
            if (locationLabel.isNotEmpty) {
              enriched['companyLocation'] = locationLabel;
            }
            enriched['companyName'] ??= company.name;
          }
          return WorkerCardModel.fromJson(enriched);
        })
        .whereType<Maid>()
        .toList();
  }

  List<Maid> _applyAvailableListLabels(
    List<Maid> maids,
    DateTime selectedDate,
  ) {
    final ref = WorkerAvailabilityLabelBuilder.dateOnly(selectedDate);
    return maids
        .map((maid) {
          final label = maid.availabilityLabel?.trim();
          final resolved = (label != null && label.isNotEmpty)
              ? label
              : WorkerAvailabilityLabelBuilder.forSelectedDate(
                  selectedDate: ref,
                  isAvailableOnDate: maid.isAvailableToday,
                );
          if (resolved == null || resolved.isEmpty) return null;
          return maid.copyWith(
            availabilityLabel: resolved,
            availableDate: ref,
            isAvailableToday: true,
          );
        })
        .whereType<Maid>()
        .toList();
  }

  List<Maid> _applyTopRatedLabels(
    List<Maid> maids,
    Set<String> availableTodayIds,
  ) {
    return maids
        .map((maid) {
          final isToday = availableTodayIds.contains(maid.id);
          final label = maid.availabilityLabel?.trim();
          final resolved = (label != null && label.isNotEmpty)
              ? label
              : WorkerAvailabilityLabelBuilder.forTopRated(
                  isAvailableToday: isToday,
                  nextAvailableDate: maid.nextAvailableDate,
                );
          return maid.copyWith(
            isAvailableToday: isToday,
            availabilityLabel: resolved,
          );
        })
        .toList();
  }

  PagedResult<Maid> _mapPagedWorkers(
    PagedResult<Map<String, dynamic>> paged,
    List<Maid> maids,
  ) {
    return PagedResult<Maid>(
      items: maids,
      page: paged.page,
      pageSize: paged.pageSize,
      totalCount: paged.totalCount,
      totalPages: paged.totalPages,
      hasNextPage: paged.hasNextPage,
      hasPreviousPage: paged.hasPreviousPage,
    );
  }

  @override
  Future<PagedResult<Maid>> getAvailableMaidsPage({
    DateTime? selectedDate,
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final ref = WorkerAvailabilityLabelBuilder.dateOnly(
        selectedDate ?? DateTime.now(),
      );
      final ctx = await _verifiedCompaniesContext();
      final paged = await remoteDataSource.getAvailableWorkersPaginated(
        date: ref,
        page: page,
        pageSize: pageSize,
      );
      final maids = _applyAvailableListLabels(
        _mapWorkerCards(paged.items, ctx.verifiedIds, ctx.byId),
        ref,
      );
      return _mapPagedWorkers(paged, maids);
    } on NetworkFailure {
      return PagedResult.empty();
    } on ServerFailure {
      return PagedResult.empty();
    } catch (_) {
      return PagedResult.empty();
    }
  }

  @override
  Future<List<Maid>> getAvailableMaidsToday({DateTime? selectedDate}) async {
    final page = await getAvailableMaidsPage(
      selectedDate: selectedDate,
      page: PaginationConstants.defaultPage,
    );
    return page.items;
  }

  Future<Set<String>> _loadTodayAvailableWorkerIds() async {
    if (_todayAvailableWorkerIdsCache != null) {
      return _todayAvailableWorkerIdsCache!;
    }
    final ids = <String>{};
    var page = PaginationConstants.defaultPage;
    var hasNext = true;
    final today = DateTime.now();

    while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
      final paged = await remoteDataSource.getAvailableWorkersPaginated(
        date: today,
        page: page,
        pageSize: PaginationConstants.defaultPageSize,
      );
      for (final json in paged.items) {
        if (json['isAvailable'] == true || json['isAvailableToday'] == true) {
          ids.add(json['id']?.toString() ?? '');
        }
      }
      hasNext = paged.hasNextPage;
      page++;
    }

    _todayAvailableWorkerIdsCache = ids;
    return ids;
  }

  Future<List<Maid>> _loadTopRatedFallbackSorted() async {
    if (_topRatedFallbackCache != null) return _topRatedFallbackCache!;

    final ctx = await _verifiedCompaniesContext();
    final summaries = await _loadWorkerRatingSummaries(ctx.verifiedIds);
    summaries.sort(_compareWorkerRatingSummaries);

    final catalog = <Maid>[];
    var page = PaginationConstants.defaultPage;
    var hasNext = true;
    while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
      final paged = await remoteDataSource.getAvailableWorkersPaginated(
        page: page,
        pageSize: PaginationConstants.defaultPageSize,
      );
      catalog.addAll(
        _mapWorkerCards(paged.items, ctx.verifiedIds, ctx.byId),
      );
      hasNext = paged.hasNextPage;
      page++;
    }

    final byWorkerId = <int, Maid>{
      for (final maid in catalog)
        if (int.tryParse(maid.id) case final id? when id > 0) id: maid,
    };

    final ranked = <Maid>[];
    for (final summary in summaries) {
      final maid = byWorkerId[summary.workerId];
      if (maid == null) continue;
      ranked.add(
        maid.copyWith(
          rating: summary.averageRating,
          reviewCount: summary.totalReviews,
        ),
      );
    }

    if (ranked.isEmpty) {
      final fallback = List<Maid>.from(catalog)
        ..sort(
          (a, b) {
            final ratingCmp = b.rating.compareTo(a.rating);
            if (ratingCmp != 0) return ratingCmp;
            return b.reviewCount.compareTo(a.reviewCount);
          },
        );
      _topRatedFallbackCache = fallback;
      return fallback;
    }

    _topRatedFallbackCache = ranked;
    return ranked;
  }

  Future<List<WorkerRatingSummary>> _loadWorkerRatingSummaries(
    Set<int> companyIds,
  ) async {
    if (companyIds.isEmpty) return [];

    final results = await Future.wait(
      companyIds.map(ratingRepository.getCompanyWorkerSummaries),
    );

    final merged = <int, WorkerRatingSummary>{};
    for (final result in results) {
      result.fold((_) {}, (list) {
        for (final summary in list) {
          if (summary.workerId <= 0) continue;
          final existing = merged[summary.workerId];
          if (existing == null ||
              _compareWorkerRatingSummaries(summary, existing) < 0) {
            merged[summary.workerId] = summary;
          }
        }
      });
    }
    return merged.values.toList();
  }

  static int _compareWorkerRatingSummaries(
    WorkerRatingSummary a,
    WorkerRatingSummary b,
  ) {
    final aHasReviews = a.totalReviews > 0;
    final bHasReviews = b.totalReviews > 0;
    if (aHasReviews != bHasReviews) {
      return aHasReviews ? -1 : 1;
    }
    final ratingCmp = b.averageRating.compareTo(a.averageRating);
    if (ratingCmp != 0) return ratingCmp;
    return b.totalReviews.compareTo(a.totalReviews);
  }

  @override
  Future<PagedResult<Maid>> getTopRatedMaidsPage({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final ctx = await _verifiedCompaniesContext();
      final paged = await remoteDataSource.tryGetTopRatedWorkersPaginated(
        page: page,
        pageSize: pageSize,
      );

      if (paged != null) {
        final todayIds = await _loadTodayAvailableWorkerIds();
        final maids = _applyTopRatedLabels(
          _mapWorkerCards(paged.items, ctx.verifiedIds, ctx.byId),
          todayIds,
        );
        return _mapPagedWorkers(paged, maids);
      }

      final sorted = await _loadTopRatedFallbackSorted();
      final todayIds = await _loadTodayAvailableWorkerIds();
      final labeled = _applyTopRatedLabels(sorted, todayIds);

      final start = (page - 1) * pageSize;
      if (start >= labeled.length) {
        return PagedResult<Maid>(
          items: const [],
          page: page,
          pageSize: pageSize,
          totalCount: labeled.length,
          totalPages: (labeled.length / pageSize).ceil(),
          hasNextPage: false,
          hasPreviousPage: page > 1,
        );
      }

      final end = start + pageSize;
      final slice = labeled.sublist(
        start,
        end > labeled.length ? labeled.length : end,
      );

      return PagedResult<Maid>(
        items: slice,
        page: page,
        pageSize: pageSize,
        totalCount: labeled.length,
        totalPages: (labeled.length / pageSize).ceil(),
        hasNextPage: end < labeled.length,
        hasPreviousPage: page > 1,
      );
    } on NetworkFailure {
      return PagedResult.empty();
    } on ServerFailure {
      return PagedResult.empty();
    } catch (_) {
      return PagedResult.empty();
    }
  }

  @override
  Future<List<Maid>> getTopRatedMaids() async {
    final page = await getTopRatedMaidsPage();
    return page.items;
  }

  @override
  Future<PagedResult<Maid>> getCompanyMaidsPage(
    int companyId, {
    DateTime? selectedDate,
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final ref = WorkerAvailabilityLabelBuilder.dateOnly(
        selectedDate ?? DateTime.now(),
      );
      final ctx = await _verifiedCompaniesContext();
      final paged = await remoteDataSource.getAvailableWorkersPaginated(
        date: ref,
        companyId: companyId,
        page: page,
        pageSize: pageSize,
      );
      final maids = _applyAvailableListLabels(
        _mapWorkerCards(paged.items, ctx.verifiedIds, ctx.byId),
        ref,
      );
      return _mapPagedWorkers(paged, maids);
    } on Failure {
      return PagedResult.empty();
    } catch (_) {
      return PagedResult.empty();
    }
  }

  @override
  Future<List<Maid>> getFavoriteMaids(
    Set<String> favoriteIds, {
    DateTime? selectedDate,
  }) async {
    if (favoriteIds.isEmpty) return [];
    final remaining = favoriteIds.toSet();
    final found = <Maid>[];
    final foundIds = <String>{};

    final topRated = await _loadTopRatedFallbackSorted();
    final todayIds = await _loadTodayAvailableWorkerIds();
    for (final maid in _applyTopRatedLabels(topRated, todayIds)) {
      if (remaining.remove(maid.id) && foundIds.add(maid.id)) {
        found.add(maid);
      }
    }

    var page = PaginationConstants.defaultPage;
    var hasNext = true;
    final ref = selectedDate ?? DateTime.now();
    while (hasNext &&
        remaining.isNotEmpty &&
        page <= PaginationConstants.maxPagesToFetch) {
      final paged = await getAvailableMaidsPage(
        selectedDate: ref,
        page: page,
      );
      for (final maid in paged.items) {
        if (remaining.remove(maid.id) && foundIds.add(maid.id)) {
          found.add(maid);
        }
      }
      hasNext = paged.hasNextPage;
      page++;
    }

    return found;
  }

  Future<Maid> _mapWorkerProfile(Map<String, dynamic> json) async {
    final enriched = Map<String, dynamic>.from(json);
    final companyIdRaw = json['companyId'];
    final companyId = companyIdRaw is int
        ? companyIdRaw
        : int.tryParse(companyIdRaw?.toString() ?? '') ?? 0;

    if (companyId > 0) {
      try {
        final ctx = await _verifiedCompaniesContext();
        final company = ctx.byId[companyId.toString()];
        if (company != null) {
          final city = company.cityName;
          final locationLabel = (city != null && city.isNotEmpty)
              ? city
              : company.location;
          if (locationLabel.isNotEmpty) {
            enriched['companyLocation'] = locationLabel;
          }
          enriched['companyName'] ??= company.name;
        }
      } catch (_) {}
    }

    final maid = WorkerCardModel.fromJson(enriched);
    final label = maid.availabilityLabel?.trim();
    if (label != null && label.isNotEmpty) return maid;

    final built = WorkerAvailabilityLabelBuilder.forSelectedDate(
      selectedDate: DateTime.now(),
      isAvailableOnDate: maid.isAvailableToday,
    );
    if (built == null) return maid;

    return maid.copyWith(
      availabilityLabel: built,
      availableDate: WorkerAvailabilityLabelBuilder.dateOnly(DateTime.now()),
    );
  }

  @override
  Future<Maid?> getWorkerById(String workerId) async {
    final id = int.tryParse(workerId);
    if (id == null || id <= 0) return null;

    try {
      final json = await remoteDataSource.getWorkerById(id);
      if (json == null) return null;
      return await _mapWorkerProfile(json);
    } on NetworkFailure {
      return null;
    } on ServerFailure {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Maid?> findWorkerCardById(String workerId) async {
    final directProfile = await getWorkerById(workerId);
    if (directProfile != null) return directProfile;

    // Fallback when GetWorkerById is unavailable or the worker is missing.
    Maid? listProfile;
    var page = PaginationConstants.defaultPage;
    var hasNext = true;
    while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
      final paged = await getAvailableMaidsPage(page: page);
      for (final maid in paged.items) {
        if (maid.id == workerId) {
          listProfile = maid;
          break;
        }
      }
      if (listProfile != null) break;
      hasNext = paged.hasNextPage;
      page++;
    }

    Maid? topRatedMatch;
    page = PaginationConstants.defaultPage;
    hasNext = true;
    while (hasNext && page <= PaginationConstants.maxPagesToFetch) {
      final paged = await getTopRatedMaidsPage(page: page);
      for (final maid in paged.items) {
        if (maid.id == workerId) {
          topRatedMatch = maid;
          break;
        }
      }
      if (topRatedMatch != null) break;
      hasNext = paged.hasNextPage;
      page++;
    }

    if (listProfile != null) {
      if (topRatedMatch != null) {
        return listProfile.copyWith(
          rating: topRatedMatch.rating,
          reviewCount: topRatedMatch.reviewCount,
          availabilityLabel:
              topRatedMatch.availabilityLabel ?? listProfile.availabilityLabel,
          isAvailableToday: topRatedMatch.isAvailableToday,
          nextAvailableDate:
              topRatedMatch.nextAvailableDate ?? listProfile.nextAvailableDate,
        );
      }
      return listProfile;
    }
    return topRatedMatch;
  }

  @override
  Future<List<ServiceCategory>> getServiceCategories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ServiceCategoryModel(
        id: '1',
        name: AppStrings.dailyCleaning,
        icon: 'cleaning_services',
      ),
      ServiceCategoryModel(
        id: '2',
        name: AppStrings.weeklyCleaning,
        icon: 'cleaning_services',
      ),
      ServiceCategoryModel(
        id: '3',
        name: AppStrings.deepCleaning,
        icon: 'cleaning_services',
      ),
      ServiceCategoryModel(
        id: '4',
        name: AppStrings.postConstruction,
        icon: 'construction',
      ),
    ];
  }

  @override
  Future<List<Language>> getAllLanguages() async {
    try {
      final languagesJson = await remoteDataSource.getAllLanguages();
      return languagesJson
          .where((json) => json['isActive'] == true)
          .map((json) => LanguageModel.fromJson(json))
          .toList();
    } on NetworkFailure {
      return [];
    } on ServerFailure {
      return [];
    } catch (_) {
      return [];
    }
  }
}
