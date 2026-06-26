import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../home/domain/entities/maid.dart';
import '../../domain/entities/company.dart';
import '../../../home/domain/usecases/get_company_maids_page_usecase.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/presentation/widgets/maid_card.dart';
import '../../domain/usecases/get_company_by_id_usecase.dart';
import '../../domain/usecases/get_companies_usecase.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bareq_nav_chevron.dart';
import '../../../reports/domain/entities/report.dart';
import '../../../reports/presentation/models/create_report_args.dart';
import '../../../ratings/domain/entities/rating_summary.dart';
import '../../../ratings/domain/usecases/rating_usecases.dart';
import '../../../ratings/presentation/rating_refresh_notifier.dart';
import '../../../ratings/presentation/widgets/rating_summary_row.dart';
import '../widgets/skeleton/companies_skeleton.dart';
import '../../../../core/utils/external_actions.dart';

/// Company Details Screen
/// Displays detailed information about a company and its maids
class CompanyDetailsScreen extends StatefulWidget {
  final String companyId;

  const CompanyDetailsScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  Company? _company;
  List<Maid> _companyMaids = [];
  CompanyRatingSummary? _companyRating;
  Map<int, WorkerRatingSummary> _workerRatingMap = {};
  bool _isLoading = true;
  bool _isLoadingMaids = false;
  String? _maidsLoadError;
  bool _isDescriptionExpanded = false;
  late final RatingRefreshNotifier _refreshNotifier;

  @override
  void initState() {
    super.initState();
    _refreshNotifier = sl<RatingRefreshNotifier>();
    _refreshNotifier.addListener(_onRatingRefresh);
    _loadCompanyDetails();
  }

  @override
  void dispose() {
    _refreshNotifier.removeListener(_onRatingRefresh);
    super.dispose();
  }

  void _onRatingRefresh() {
    final companyId = int.tryParse(widget.companyId);
    if (companyId == null || _refreshNotifier.companyId != companyId) return;
    _loadRatings(companyId, invalidate: true);
  }

  Future<void> _loadCompanyDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to parse companyId as int for API call
      final companyIdInt = int.tryParse(widget.companyId);
      
      if (companyIdInt != null) {
        // Load company details from API
        final getCompanyByIdUseCase = sl<GetCompanyByIdUseCase>();
        final result = await getCompanyByIdUseCase(companyIdInt);
        
        result.fold(
          (failure) {
            // If API fails, fall back to mock data
            _loadCompanyFromMock();
          },
          (company) {
            if (mounted) {
              setState(() {
                _company = company;
                _isLoading = false;
              });
              _loadCompanyMaids(company);
              _loadRatings(companyIdInt, invalidate: false);
            }
          },
        );
      } else {
        // If companyId is not a valid int, use mock data
        _loadCompanyFromMock();
      }
    } catch (e) {
      // On error, use mock data
      _loadCompanyFromMock();
    }
  }

  Future<void> _loadCompanyFromMock() async {
    // Fallback to mock data if API fails
    final getCompaniesUseCase = sl<GetCompaniesUseCase>();
    final companies = await getCompaniesUseCase();
    
    final company = companies.firstWhere(
      (c) => c.id == widget.companyId,
      orElse: () => companies.first,
    );
    
    if (mounted) {
      setState(() {
        _company = company;
        _isLoading = false;
      });
      _loadCompanyMaids(company);
    }
  }

  Future<void> _loadCompanyMaids(Company company) async {
    final companyId = int.tryParse(widget.companyId) ?? int.tryParse(company.id);
    if (companyId == null) {
      if (mounted) {
        setState(() {
          _companyMaids = [];
          _isLoadingMaids = false;
          _maidsLoadError = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingMaids = true;
        _maidsLoadError = null;
      });
    }

    try {
      final allMaids = <Maid>[];
      var page = 1;
      var hasNext = true;
      while (hasNext && page <= 25) {
        final paged = await sl<GetCompanyMaidsPageUseCase>()(
          companyId,
          page: page,
          pageSize: 20,
        );
        allMaids.addAll(paged.items);
        hasNext = paged.hasNextPage;
        page++;
      }

      if (mounted) {
        setState(() {
          _companyMaids = allMaids;
          _isLoadingMaids = false;
          _maidsLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _companyMaids = [];
          _isLoadingMaids = false;
          _maidsLoadError = e.toString();
        });
      }
    }

    if (mounted) {
      await _loadRatings(companyId, invalidate: false);
    }
  }

  Future<void> _loadRatings(int companyId, {required bool invalidate}) async {
    if (invalidate) {
      sl<InvalidateRatingCacheUseCase>().forCompany(companyId);
    }

    final companyResult = await sl<GetCompanyRatingSummaryUseCase>()(companyId);
    final workersResult =
        await sl<GetCompanyWorkerSummariesUseCase>()(companyId);

    if (!mounted) return;

    CompanyRatingSummary? companyRating;
    final workerMap = <int, WorkerRatingSummary>{};

    companyResult.fold((_) {}, (summary) => companyRating = summary);
    workersResult.fold((_) {}, (list) {
      for (final item in list) {
        workerMap[item.workerId] = item;
      }
    });

    setState(() {
      _companyRating = companyRating;
      _workerRatingMap = workerMap;
    });
  }

  Future<void> _refreshAll() async {
    final companyId = int.tryParse(widget.companyId);
    if (companyId == null || _company == null) return;
    sl<InvalidateRatingCacheUseCase>().forCompany(companyId);
    sl<RatingRefreshNotifier>().notifyCompanyInvalidated(companyId);
    await _loadRatings(companyId, invalidate: true);
    await _loadCompanyMaids(_company!);
  }

  WorkerRatingSummary? _summaryForMaid(Maid maid) {
    final workerId = int.tryParse(maid.id);
    if (workerId == null) return null;
    return _workerRatingMap[workerId];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        showBackButton: true,
        title: l10n?.translate('companies') ?? AppStrings.companies,
      ),
      body: _isLoading
          ? const CompaniesSkeleton()
          : _company == null
              ? _buildErrorState(context)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Company Header Section
          _buildCompanyHeader(context)
              .animate()
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
              .scale(duration: 280.ms, curve: Curves.easeOutCubic),
          
          // Company Contact Information
          _buildContactInfo(context)
              .animate(delay: 50.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 24),

          _buildWorkersSection(context)
              .animate(delay: 75.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 24),

          _buildReportCompanySection(context)
              .animate(delay: 100.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }

  Widget _buildWorkersSection(BuildContext context) {
    final l10n = L10n.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.translate('companyWorkers') ??
                    l10n?.translate('companyMaids') ??
                    'Company workers',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (!_isLoadingMaids && _companyMaids.isNotEmpty)
                Text(
                  '${_companyMaids.length} ${l10n?.translate('maids') ?? AppStrings.maids}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingMaids)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_maidsLoadError != null)
            _buildMaidsErrorState(context)
          else if (_companyMaids.isEmpty)
            _buildEmptyMaidsState(context)
          else
            _buildWorkersGrid(context),
        ],
      ),
    );
  }

  Widget _buildMaidsErrorState(BuildContext context) {
    final l10n = L10n.of(context);
    return Center(
      child: Column(
        children: [
          Text(
            l10n?.translate('workersLoadError') ??
                'Could not load workers. Pull to refresh.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed:
                _company != null ? () => _loadCompanyMaids(_company!) : null,
            child: Text(l10n?.translate('retry') ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.88,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _companyMaids.length,
      itemBuilder: (context, index) {
        final maid = _companyMaids[index];
        return MaidCard(
          maid: maid,
          isGridLayout: true,
          prominentAvailabilityBadge: true,
          showRatingFromSummary: true,
          workerRatingSummary: _summaryForMaid(maid),
          onTap: () => context.go(AppStrings.maidDetailsRoute(maid.id)),
        )
            .animate(delay: (index * 30).ms)
            .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildCompanyHeader(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.surface,
          ],
          stops: const [0.0, 0.75], // Reduced gradient height by ~15-20%
        ),
      ),
      child: Column(
        children: [
          // Company Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.business,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Company Name - Outside gradient area for cleaner reading
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _company!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_company!.isVerified) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
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
          const SizedBox(height: 8),

          if (_companyRating != null) ...[
            RatingSummaryRow(
              summary: _companyRating!,
              starSize: 20,
              alignment: MainAxisAlignment.center,
              textStyle: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_companyRating!.hasReviews &&
                _companyRating!.totalActiveWorkers > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n?.translate('ratedWorkersSubtitle') ??
                    '${_companyRating!.ratedWorkersCount} ${l10n?.translate('ratedWorkersLabel') ?? 'rated workers'} · ${_companyRating!.totalActiveWorkers} ${l10n?.translate('maids') ?? 'maids'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ] else
            Text(
              l10n?.translate('noReviewsYet') ?? 'لا توجد تقييمات',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          
          // Description with "Show More"
          if (_company!.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    _company!.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5, // Increased line-height
                        ),
                    textAlign: TextAlign.center,
                    maxLines: _isDescriptionExpanded ? null : 2,
                    overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (_company!.description.length > 100) // Only show if description is long
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded
                            ? (l10n?.translate('showLess') ?? 'Show Less')
                            : (l10n?.translate('showMore') ?? 'Show More'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.translate('contactInformation') ?? AppStrings.contactInformation,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          
          // Location - Actionable (tap to open maps)
          if (_company!.location.trim().isNotEmpty)
            _buildContactRow(
              context,
              icon: Icons.location_on,
              label: l10n?.translate('location') ?? AppStrings.location,
              value: _company!.location,
              actionLabel: l10n?.translate('openInMaps') ?? 'Open in maps',
              onTap: () => launchMapsForAddress(context, _company!.location),
            ),
          if (_company!.location.trim().isNotEmpty &&
              _company!.phoneNumber.trim().isNotEmpty)
            const SizedBox(height: 12),
          if (_company!.phoneNumber.trim().isNotEmpty)
            _buildContactRow(
              context,
              icon: Icons.phone,
              label: l10n?.translate('phoneNumber') ?? AppStrings.phoneNumber,
              value: _company!.phoneNumber,
              actionLabel: l10n?.translate('callCompany') ?? 'Call company',
              onTap: () => launchPhoneCall(context, _company!.phoneNumber),
            ),
          if (_company!.yearsInBusiness > 0) ...[
            const SizedBox(height: 12),
            _buildContactRow(
              context,
              icon: Icons.calendar_today,
              label: l10n?.translate('yearsInBusiness') ?? AppStrings.yearsInBusiness,
              value: '${_company!.yearsInBusiness} ${l10n?.translate('years') ?? AppStrings.years}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    final isAction = onTap != null;
    return Semantics(
      button: isAction,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (isAction && actionLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        actionLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isAction) const BareqNavChevron(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMaidsState(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            )
                .animate(delay: 50.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                .scale(duration: 280.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
            Text(
              l10n?.translate('noMaidsAvailable') ?? AppStrings.noMaidsAvailable,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = L10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            )
                .animate(delay: 50.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                .scale(duration: 280.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
            Text(
              l10n?.translate('error') ?? AppStrings.error,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(
              l10n?.translate('companyNotFound') ?? AppStrings.companyNotFound,
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

  Widget _buildReportCompanySection(BuildContext context) {
    if (_company == null) return const SizedBox.shrink();
    final companyId = int.tryParse(_company!.id);
    if (companyId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(Icons.report_outlined, color: Colors.red.shade400),
          title: Text(
            L10n.translate(context, 'reportCompany'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const BareqNavChevron(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
          ),
          onTap: () {
            context.push(
              AppStrings.routeCreateReport,
              extra: CreateReportArgs(
                targetType: ReportTargetType.company,
                targetId: companyId,
                targetName: _company!.name,
                returnRoute: AppStrings.companyDetailsRoute(
                  companyId.toString(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

