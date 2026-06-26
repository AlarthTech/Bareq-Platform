import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../auth/domain/usecases/get_cities_usecase.dart';
import '../../../home/domain/entities/language.dart';
import '../../../home/domain/entities/maid.dart';
import '../../../home/domain/usecases/get_languages_usecase.dart';
import '../../../home/domain/usecases/get_available_maids_page_usecase.dart';
import '../../../../core/network/pagination_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/language_lookup.dart';
import '../../../../core/utils/western_numerals.dart';
import '../models/worker_filter_state.dart';
import '../../../home/presentation/widgets/maid_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bottom_nav_bar.dart';
import '../widgets/filters_bottom_sheet.dart';
import '../widgets/skeleton/search_results_skeleton.dart';

/// Full Search & Filter Screen
/// Provides comprehensive search and filtering capabilities
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.selectedDate, this.initialMinRating});

  final DateTime? selectedDate;
  final double? initialMinRating;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  WorkerFilterState _filters = const WorkerFilterState();
  List<String> _cityOptions = [];
  List<Language> _languageCatalog = [];

  // Maids list
  final ScrollController _scrollController = ScrollController();
  CancelToken? _cancelToken;

  List<Maid> _allMaids = [];
  List<Maid> _filteredMaids = [];
  bool _isLoading = true;
  bool _isRefreshingList = false;
  bool _isLoadingMore = false;
  bool _hasLoadedOnce = false;
  bool _hasMore = true;
  int _currentPage = PaginationConstants.defaultPage;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    var filters = const WorkerFilterState();
    if (widget.selectedDate != null) {
      final d = widget.selectedDate!;
      filters = filters.copyWith(
        bookingDate: DateTime(d.year, d.month, d.day),
      );
    }
    if (widget.initialMinRating != null) {
      filters = filters.copyWith(minRating: widget.initialMinRating!);
    }
    _filters = filters;
    _scrollController.addListener(_onScrollNearEnd);
    _loadCityOptions();
    _loadLanguageCatalog();
    _loadMaids(reset: true);
    _searchController.addListener(_onSearchChanged);
  }

  void _onScrollNearEnd() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMaids(reset: false);
    }
  }

  Future<void> _loadLanguageCatalog() async {
    try {
      final languages = await sl<GetLanguagesUseCase>()();
      if (mounted) {
        setState(() => _languageCatalog = languages);
      }
    } catch (_) {}
  }

  Future<void> _loadCityOptions() async {
    final result = await sl<GetCitiesUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) {},
      (cities) {
        setState(() {
          _cityOptions =
              cities
                  .where((c) => c.isActive)
                  .map((c) => c.name)
                  .toSet()
                  .toList()
                ..sort();
        });
      },
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    _scrollController.removeListener(_onScrollNearEnd);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadMaids({required bool reset}) async {
    if (reset) {
      if (_isLoadingMore) return;
      _cancelToken?.cancel('reload');
      _cancelToken = CancelToken();
      if (mounted) {
        final showFullSkeleton = !_hasLoadedOnce;
        setState(() {
          _loadError = null;
          _currentPage = PaginationConstants.defaultPage;
          _hasMore = true;
          if (showFullSkeleton) {
            _isLoading = true;
            _isRefreshingList = false;
            _allMaids = [];
          } else {
            _isLoading = false;
            _isRefreshingList = true;
          }
        });
      }
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      if (mounted) setState(() => _isLoadingMore = true);
    }

    final date = _filters.bookingDate ?? widget.selectedDate;
    final page = reset ? PaginationConstants.defaultPage : _currentPage + 1;

    try {
      final paged = await sl<GetAvailableMaidsPageUseCase>()(
        selectedDate: date,
        page: page,
        pageSize: PaginationConstants.defaultPageSize,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _allMaids = paged.items;
        } else {
          final ids = _allMaids.map((m) => m.id).toSet();
          _allMaids.addAll(
            paged.items.where((m) => ids.add(m.id)),
          );
        }
        _currentPage = page;
        _hasMore = paged.hasNextPage;
        _isLoading = false;
        _isRefreshingList = false;
        _isLoadingMore = false;
        _hasLoadedOnce = true;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure ? e.message : e.toString();
      setState(() {
        _loadError = msg;
        _isLoading = false;
        _isRefreshingList = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    if (_allMaids.isEmpty) return;

    final searchQuery = _searchController.text.toLowerCase();
    
    final filtered = _allMaids.where((maid) {
      // Search query filter
      if (searchQuery.isNotEmpty) {
        final matchesName = maid.name.toLowerCase().contains(searchQuery);
        final matchesCompany = maid.companyName?.toLowerCase().contains(searchQuery) ?? false;
        if (!matchesName && !matchesCompany) {
          return false;
        }
      }

      // Languages filter (match by API id / code, display names in UI)
      if (_filters.selectedLanguages.isNotEmpty) {
        if (!LanguageLookup.maidMatchesLanguageFilter(
          maid,
          _filters.selectedLanguages,
          _languageCatalog,
        )) {
          return false;
        }
      }

      // Nationality filter
      if (_filters.selectedNationalities.isNotEmpty) {
        final nation = maid.nationality?.trim();
        if (nation == null ||
            !_filters.selectedNationalities.any(
              (n) => n.toLowerCase() == nation.toLowerCase(),
            )) {
          return false;
        }
      }

      // Rating filter
      if (_filters.minRating > 0) {
        if (maid.rating < _filters.minRating) {
          return false;
        }
      }

      // Experience filter
      if (_filters.minExperience > 0) {
        if (maid.experienceYears < _filters.minExperience) {
          return false;
        }
      }

      // City filter
      if (_filters.selectedCity != null) {
        final loc = maid.companyLocation?.trim().toLowerCase() ?? '';
        final city = _filters.selectedCity!.trim().toLowerCase();
        if (loc != city && !loc.contains(city)) {
          return false;
        }
      }

      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _filteredMaids = filtered;
      });
    }
  }

  void _onFiltersApplied(WorkerFilterState filters) {
    final dateChanged =
        !_sameDay(_filters.bookingDate, filters.bookingDate);
    setState(() => _filters = filters);
    if (dateChanged) {
      _loadMaids(reset: true);
    } else {
      _applyFilters();
    }
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _deriveNationalities() {
    return _allMaids
        .map((m) => m.nationality?.trim())
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<LanguageFilterOption> _buildLanguageFilterOptions() {
    return LanguageLookup.filterOptions(
      catalog: _languageCatalog,
      maids: _allMaids,
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => FiltersBottomSheet(
          initialFilters: _filters,
          cityOptions: _cityOptions,
          nationalityOptions: _deriveNationalities(),
          languageOptions: _buildLanguageFilterOptions(),
          onApplyFilters: _onFiltersApplied,
          resultCount: _filteredMaids.length,
        ),
      ),
    );
  }

  bool get _hasActiveFilters => _filters.hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        showBackButton: true,
        title: l10n?.translate('search') ?? AppStrings.search,
      ),
      body: Column(
        children: [
          // Search Field with Filter Icon
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          if (_hasActiveFilters) _buildActiveFilters(context),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = L10n.of(context);
                    final showSpinner =
                        _isLoading || _isRefreshingList || _isLoadingMore;
                    final resultsCount =
                        showSpinner && _filteredMaids.isEmpty
                            ? 0
                            : _filteredMaids.length;
                    final resultsText = resultsCount == 1
                        ? (l10n?.translate('resultFound') ?? 'result found')
                        : (l10n?.translate('resultsFound') ?? AppStrings.resultsFound);
                    return Text(
                      '$resultsCount $resultsText',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    );
                  },
                ),
                if (_isRefreshingList)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const SearchResultsSkeleton()
                : _loadError != null && _allMaids.isEmpty
                    ? _buildErrorState(context)
                    : _filteredMaids.isEmpty && !_isRefreshingList
                        ? _buildEmptyState(context)
                        : _buildMaidsGrid(context),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSearchField() {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n?.translate('searchMaidsCompanies') ?? AppStrings.searchMaidsCompanies,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
            decoration: BoxDecoration(
              color: _hasActiveFilters ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasActiveFilters
                    ? AppColors.primary
                    : AppColors.border.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune,
                color:
                    _hasActiveFilters ? Colors.white : AppColors.textSecondary,
              ),
              onPressed: _showFiltersBottomSheet,
              tooltip: l10n?.translate('filters') ?? AppStrings.filters,
            ),
          ),
      ],
    );
  }

  Widget _buildActiveFilters(BuildContext context) {
    final filterChips = <Widget>[];
    final l10n = L10n.of(context);

    if (_filters.bookingDate != null) {
      final locale = l10n?.locale.toString() ?? 'en';
      final label = WesternNumerals.normalize(
        DateFormat.yMMMd(locale).format(_filters.bookingDate!),
      );
      filterChips.add(_buildActiveFilterChip(
        context,
        label: label,
        icon: Icons.calendar_today,
        onRemove: () {
          setState(() => _filters = _filters.copyWith(clearBookingDate: true));
          _loadMaids(reset: true);
        },
      ));
    }

    if (_filters.selectedCity != null) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label: _filters.selectedCity!,
        icon: Icons.location_on,
        onRemove: () {
          setState(() => _filters = _filters.copyWith(clearCity: true));
          _applyFilters();
        },
      ));
    }

    if (_filters.minRating > 0) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label:
            '${_filters.minRating.toStringAsFixed(1)}+ ${l10n?.translate('rating') ?? AppStrings.rating}',
        icon: Icons.star,
        onRemove: () {
          setState(() => _filters = _filters.copyWith(minRating: 0));
          _applyFilters();
        },
      ));
    }

    if (_filters.minExperience > 0) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label:
            '${_filters.minExperience}+ ${l10n?.translate('years') ?? AppStrings.years}',
        icon: Icons.work_outline,
        onRemove: () {
          setState(() => _filters = _filters.copyWith(minExperience: 0));
          _applyFilters();
        },
      ));
    }

    for (final nation in _filters.selectedNationalities) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label: nation,
        icon: Icons.flag_outlined,
        onRemove: () {
          setState(() {
            final next = Set<String>.from(_filters.selectedNationalities)
              ..remove(nation);
            _filters = _filters.copyWith(selectedNationalities: next);
          });
          _applyFilters();
        },
      ));
    }

    for (final languageId in _filters.selectedLanguages) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label: LanguageLookup.displayNameForFilterId(
          _languageCatalog,
          languageId,
        ),
        icon: Icons.language,
        onRemove: () {
          setState(() {
            final next = Set<String>.from(_filters.selectedLanguages)
              ..remove(languageId);
            _filters = _filters.copyWith(selectedLanguages: next);
          });
          _applyFilters();
        },
      ));
    }

    if (filterChips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.translate('activeFilters') ?? AppStrings.activeFilters,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (filterChips.length >= 2)
                TextButton(
                  onPressed: () {
                    setState(() => _filters = const WorkerFilterState());
                    _loadMaids(reset: true);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    l10n?.translate('clearAll') ?? AppStrings.clearAll,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: filterChips,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaidsGrid(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: _isRefreshingList ? 0.45 : 1,
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.12,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredMaids.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _filteredMaids.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final maid = _filteredMaids[index];
              return MaidCard(
                maid: maid,
                isGridLayout: true,
                onTap: _isRefreshingList
                    ? null
                    : () {
                        context.push(AppStrings.maidDetailsRoute(maid.id));
                      },
              );
            },
          ),
        ),
        if (_isRefreshingList)
          const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _loadError ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _loadMaids(reset: true),
              child: Text(l10n?.translate('retry') ?? AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.translate('noResultsFound') ?? AppStrings.noResultsFound,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.translate('tryDifferentFilters') ?? AppStrings.tryDifferentFilters,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
