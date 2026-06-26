import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/company.dart';
import '../../domain/usecases/get_companies_usecase.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bottom_nav_bar.dart';
import '../widgets/company_card.dart';
import '../../../ratings/presentation/widgets/company_card_rating.dart';
import '../widgets/skeleton/companies_skeleton.dart';
import '../widgets/company_filters_bottom_sheet.dart';

/// Companies Screen
/// Displays a list of all cleaning companies with search and filters
class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter states
  Set<String> _selectedServices = {};
  String? _selectedLocation;
  double _minRating = 0.0;
  bool? _verifiedOnly;
  
  // Companies list
  List<Company> _allCompanies = [];
  List<Company> _filteredCompanies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
    });

    final getCompaniesUseCase = sl<GetCompaniesUseCase>();

    final companies = await getCompaniesUseCase();

    if (mounted) {
      setState(() {
        _allCompanies = companies;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    if (_allCompanies.isEmpty) return;

    final searchQuery = _searchController.text.toLowerCase();
    
    final filtered = _allCompanies.where((company) {
      // Search query filter
      if (searchQuery.isNotEmpty) {
        final matchesName = company.name.toLowerCase().contains(searchQuery);
        final matchesDescription = company.description.toLowerCase().contains(searchQuery);
        if (!matchesName && !matchesDescription) {
          return false;
        }
      }

      // Services filter
      if (_selectedServices.isNotEmpty) {
        final hasMatchingService = company.services.any(
          (service) => _selectedServices.contains(service),
        );
        if (!hasMatchingService) {
          return false;
        }
      }

      // Location filter
      if (_selectedLocation != null) {
        if (company.location != _selectedLocation) {
          return false;
        }
      }

      // Rating filter
      if (_minRating > 0) {
        if (company.rating < _minRating) {
          return false;
        }
      }

      // Verified filter
      if (_verifiedOnly == true) {
        if (!company.isVerified) {
          return false;
        }
      }

      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _filteredCompanies = filtered;
      });
    }
  }

  void _onFiltersApplied(
    Set<String> services,
    String? location,
    double minRating,
    bool? verifiedOnly,
  ) {
    setState(() {
      _selectedServices = services;
      _selectedLocation = location;
      _minRating = minRating;
      _verifiedOnly = verifiedOnly;
    });
    _applyFilters();
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => CompanyFiltersBottomSheet(
          selectedServices: _selectedServices,
          selectedLocation: _selectedLocation,
          minRating: _minRating,
          verifiedOnly: _verifiedOnly,
          onApplyFilters: _onFiltersApplied,
        ),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _selectedServices.isNotEmpty ||
        _selectedLocation != null ||
        _minRating > 0.0 ||
        _verifiedOnly != null;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedServices.isNotEmpty) count += _selectedServices.length;
    if (_selectedLocation != null) count += 1;
    if (_minRating > 0.0) count += 1;
    if (_verifiedOnly == true) count += 1;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        showBackButton: false,
        title: l10n?.translate('companies') ?? AppStrings.companies,
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
          )
              .animate()
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
          
          // Active Filters (if any)
          if (_hasActiveFilters)
            _buildActiveFilters(context)
                .animate(delay: 30.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
          
          // Results Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = L10n.of(context);
                    final resultsCount = _filteredCompanies.length;
                    final resultsText = resultsCount == 1
                        ? (l10n?.translate('companyFound') ?? AppStrings.companyFound)
                        : (l10n?.translate('companiesFound') ?? AppStrings.companiesFound);
                    return Text(
                      '${_isLoading ? 0 : resultsCount} $resultsText',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    );
                  },
                ),
              ],
            ),
          )
              .animate(delay: 50.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

          // Companies List
          Expanded(
            child: _isLoading
                ? const CompaniesSkeleton()
                : _filteredCompanies.isEmpty
                    ? _buildEmptyState(context)
                    : _buildCompaniesList(context),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
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
                hintText: l10n?.translate('searchCompanies') ?? AppStrings.searchCompanies,
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
          child: Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: _hasActiveFilters ? Colors.white : AppColors.textSecondary,
                ),
                onPressed: _showFiltersBottomSheet,
                tooltip: l10n?.translate('filters') ?? AppStrings.filters,
              ),
              // Filter count badge
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters(BuildContext context) {
    final filterChips = <Widget>[];
    final l10n = L10n.of(context);

    // Services
    if (_selectedServices.isNotEmpty) {
      for (var service in _selectedServices) {
        filterChips.add(_buildActiveFilterChip(
          context,
          label: service,
          icon: Icons.cleaning_services,
          onRemove: () {
            setState(() {
              _selectedServices.remove(service);
            });
            _applyFilters();
          },
        ));
      }
    }

    // Location
    if (_selectedLocation != null) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label: _selectedLocation!,
        icon: Icons.location_on,
        onRemove: () {
          setState(() {
            _selectedLocation = null;
          });
          _applyFilters();
        },
      ));
    }

    // Rating
    if (_minRating > 0) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label: '${_minRating.toStringAsFixed(1)}+ ${l10n?.translate('rating') ?? AppStrings.rating}',
        icon: Icons.star,
        onRemove: () {
          setState(() {
            _minRating = 0.0;
          });
          _applyFilters();
        },
      ));
    }

    // Verified
    if (_verifiedOnly == true) {
      filterChips.add(_buildActiveFilterChip(
        context,
        label: l10n?.translate('verifiedOnly') ?? AppStrings.verifiedOnly,
        icon: Icons.verified,
        onRemove: () {
          setState(() {
            _verifiedOnly = null;
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
          Text(
            l10n?.translate('activeFilters') ?? AppStrings.activeFilters,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesList(BuildContext context) {
    // Separate boosted and regular companies
    final boostedCompanies = _filteredCompanies.where((c) => c.isBoosted).toList();
    final regularCompanies = _filteredCompanies.where((c) => !c.isBoosted).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Boosted Companies (Full Width)
        if (boostedCompanies.isNotEmpty) ...[
          ...boostedCompanies.asMap().entries.map((entry) {
            final index = entry.key;
            final company = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBoostedCompanyCard(context, company)
                  .animate(delay: (100 + index * 50).ms)
                  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                  .scale(duration: 280.ms, curve: Curves.easeOutCubic),
            );
          }),
          const SizedBox(height: 8),
        ],
        
        // Regular Companies Grid
        if (regularCompanies.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.90,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: regularCompanies.length,
            itemBuilder: (context, index) {
              final company = regularCompanies[index];
              final baseDelay = boostedCompanies.isNotEmpty ? 200 : 100;
              return CompanyCard(
                company: company,
                onTap: () {
                  context.go(AppStrings.companyDetailsRoute(company.id));
                },
              )
                  .animate(delay: (baseDelay + index * 30).ms)
                  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                  .scale(duration: 280.ms, curve: Curves.easeOutCubic);
            },
          ),
      ],
    );
  }
  
  Widget _buildBoostedCompanyCard(BuildContext context, Company company) {
    final l10n = L10n.of(context);
    return InkWell(
      onTap: () {
        context.go(AppStrings.companyDetailsRoute(company.id));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3), // Reduced pink border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withOpacity(0.08), // Reduced pink shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo Section
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // Unified Featured + Verified badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Featured badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n?.translate('featured') ?? 'Featured',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Verified badge (inline with featured)
                        if (company.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Company Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Company Name
                    Text(
                      company.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Rating from Summary API
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final companyId = int.tryParse(company.id);
                              if (companyId == null) {
                                if (company.reviewCount > 0 &&
                                    company.rating > 0) {
                                  return Text(
                                    '${company.rating.toStringAsFixed(1)} (${company.reviewCount})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }
                              return CompanyCardRating(
                                companyId: companyId,
                                iconSize: 16,
                                fontSize: 13,
                              );
                            },
                          ),
                        ),
                        if (company.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            company.location,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Maids count
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${company.totalMaids} ${l10n?.translate('maids') ?? 'maids'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
              Icons.business_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            )
                .animate(delay: 50.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                .scale(duration: 280.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 24),
            Text(
              l10n?.translate('noCompaniesFound') ?? AppStrings.noCompaniesFound,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(
              l10n?.translate('checkBackLater') ?? AppStrings.checkBackLater,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

