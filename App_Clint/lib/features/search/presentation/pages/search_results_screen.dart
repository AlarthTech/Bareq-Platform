import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../home/domain/entities/maid.dart';
import '../../../home/domain/usecases/get_available_maids_usecase.dart';
import '../../../home/domain/entities/language.dart';
import '../../../home/domain/usecases/get_languages_usecase.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/language_lookup.dart';
import '../../../home/presentation/widgets/maid_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bottom_nav_bar.dart';
import '../models/worker_filter_state.dart';
import '../widgets/skeleton/search_results_skeleton.dart';

/// Search Results Screen — displays filtered worker search results.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    this.searchQuery,
    this.bookingDate,
    this.selectedLanguages,
    this.selectedNationalities,
    this.minRating,
    this.minExperience,
    this.selectedCity,
  });

  final String? searchQuery;
  final DateTime? bookingDate;
  final Set<String>? selectedLanguages;
  final Set<String>? selectedNationalities;
  final double? minRating;
  final int? minExperience;
  final String? selectedCity;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Maid> _results = [];
  bool _isLoading = true;
  List<Language> _languageCatalog = [];

  late WorkerFilterState _filters;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadLanguageCatalog();
    _searchQuery = widget.searchQuery;
    _filters = WorkerFilterState(
      bookingDate: widget.bookingDate,
      selectedCity: widget.selectedCity,
      minRating: widget.minRating ?? 0,
      minExperience: widget.minExperience ?? 0,
      selectedNationalities: Set<String>.from(
        widget.selectedNationalities ?? {},
      ),
      selectedLanguages: Set<String>.from(widget.selectedLanguages ?? {}),
    );
    _loadResults();
  }

  Future<void> _loadLanguageCatalog() async {
    try {
      final languages = await sl<GetLanguagesUseCase>()();
      if (mounted) setState(() => _languageCatalog = languages);
    } catch (_) {}
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    final availableMaids = await sl<GetAvailableMaidsUseCase>()(
      selectedDate: _filters.bookingDate,
    );

    final filtered = availableMaids.where(_matchesFilters).toList();

    if (mounted) {
      setState(() {
        _results = filtered;
        _isLoading = false;
      });
    }
  }

  bool _matchesFilters(Maid maid) {
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      final matchesName = maid.name.toLowerCase().contains(query);
      final matchesCompany =
          maid.companyName?.toLowerCase().contains(query) ?? false;
      if (!matchesName && !matchesCompany) return false;
    }

    if (_filters.selectedLanguages.isNotEmpty) {
      if (!LanguageLookup.maidMatchesLanguageFilter(
        maid,
        _filters.selectedLanguages,
        _languageCatalog,
      )) {
        return false;
      }
    }

    if (_filters.selectedNationalities.isNotEmpty) {
      final nation = maid.nationality?.trim();
      if (nation == null ||
          !_filters.selectedNationalities.any(
            (n) => n.toLowerCase() == nation.toLowerCase(),
          )) {
        return false;
      }
    }

    if (_filters.minRating > 0 && maid.rating < _filters.minRating) {
      return false;
    }

    if (_filters.minExperience > 0 &&
        maid.experienceYears < _filters.minExperience) {
      return false;
    }

    if (_filters.selectedCity != null) {
      final loc = maid.companyLocation?.trim().toLowerCase() ?? '';
      final city = _filters.selectedCity!.trim().toLowerCase();
      if (loc != city && !loc.contains(city)) return false;
    }

    return true;
  }

  bool _hasActiveFilters() {
    return (_searchQuery != null && _searchQuery!.isNotEmpty) ||
        _filters.hasActiveFilters;
  }

  Widget _buildActiveFilters(BuildContext context) {
    final filterChips = <Widget>[];
    final l10n = L10n.of(context);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filterChips.add(_buildFilterChip(
        context,
        label: _searchQuery!,
        icon: Icons.search,
        onRemove: () {
          _searchQuery = null;
          _loadResults();
        },
      ));
    }

    if (_filters.bookingDate != null) {
      final locale = l10n?.locale.toString() ?? 'en';
      filterChips.add(_buildFilterChip(
        context,
        label: WesternNumerals.normalize(
          DateFormat.yMMMd(locale).format(_filters.bookingDate!),
        ),
        icon: Icons.calendar_today,
        onRemove: () {
          _filters = _filters.copyWith(clearBookingDate: true);
          _loadResults();
        },
      ));
    }

    if (_filters.selectedCity != null) {
      filterChips.add(_buildFilterChip(
        context,
        label: _filters.selectedCity!,
        icon: Icons.location_on,
        onRemove: () {
          _filters = _filters.copyWith(clearCity: true);
          _loadResults();
        },
      ));
    }

    if (_filters.minRating > 0) {
      filterChips.add(_buildFilterChip(
        context,
        label:
            '${_filters.minRating.toStringAsFixed(1)}+ ${l10n?.translate('rating') ?? AppStrings.rating}',
        icon: Icons.star,
        onRemove: () {
          _filters = _filters.copyWith(minRating: 0);
          _loadResults();
        },
      ));
    }

    if (_filters.minExperience > 0) {
      filterChips.add(_buildFilterChip(
        context,
        label:
            '${_filters.minExperience}+ ${l10n?.translate('years') ?? AppStrings.years}',
        icon: Icons.work_outline,
        onRemove: () {
          _filters = _filters.copyWith(minExperience: 0);
          _loadResults();
        },
      ));
    }

    for (final nation in _filters.selectedNationalities) {
      filterChips.add(_buildFilterChip(
        context,
        label: nation,
        icon: Icons.flag_outlined,
        onRemove: () {
          final next = Set<String>.from(_filters.selectedNationalities)
            ..remove(nation);
          _filters = _filters.copyWith(selectedNationalities: next);
          _loadResults();
        },
      ));
    }

    for (final languageId in _filters.selectedLanguages) {
      filterChips.add(_buildFilterChip(
        context,
        label: LanguageLookup.displayNameForFilterId(
          _languageCatalog,
          languageId,
        ),
        icon: Icons.language,
        onRemove: () {
          final next = Set<String>.from(_filters.selectedLanguages)
            ..remove(languageId);
          _filters = _filters.copyWith(selectedLanguages: next);
          _loadResults();
        },
      ));
    }

    if (filterChips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.translate('activeFilters') ?? AppStrings.activeFilters,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: filterChips),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        showBackButton: true,
        title: l10n?.translate('searchResults') ?? AppStrings.searchResults,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          !_isLoading
                              ? Text(
                                '${_results.length} ${l10n?.translate('resultsFound') ?? AppStrings.resultsFound}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              )
                              : const SizedBox.shrink(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      color: AppColors.primary,
                      onPressed: () => context.go(AppStrings.routeSearch),
                      tooltip:
                          l10n?.translate('modifyFilters') ?? 'Modify Filters',
                    ),
                  ],
                ),
                if (_hasActiveFilters()) ...[
                  const SizedBox(height: 8),
                  _buildActiveFilters(context),
                ],
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const SearchResultsSkeleton()
                    : _results.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n?.translate('noResultsFound') ??
                              AppStrings.noResultsFound,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.12,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final maid = _results[index];
                        return MaidCard(
                          maid: maid,
                          isGridLayout: true,
                          onTap:
                              () => context.push(
                                AppStrings.maidDetailsRoute(maid.id),
                              ),
                        );
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}
