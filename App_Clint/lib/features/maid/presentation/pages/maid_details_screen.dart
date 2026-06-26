import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../home/domain/entities/maid.dart';
import '../../../home/domain/usecases/get_languages_usecase.dart';
import '../../../home/domain/usecases/get_worker_by_id_usecase.dart';
import '../../../home/domain/entities/language.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/favorites/favorites_provider.dart';
import '../../../reports/domain/entities/report.dart';
import '../../../reports/presentation/models/create_report_args.dart';
import '../../../reviews/presentation/pages/worker_reviews_section.dart';
import '../../../ratings/presentation/widgets/worker_rating_display.dart';
import '../../../home/presentation/widgets/maid_availability_badge.dart';
import '../../../../core/utils/language_lookup.dart';
import '../widgets/skeleton/maid_details_skeleton.dart';

class _WorkerDetailsData {
  const _WorkerDetailsData({
    required this.maid,
    required this.languages,
  });

  final Maid? maid;
  final List<Language> languages;
}

/// Maid Details Screen
/// Displays comprehensive information about a selected maid
class MaidDetailsScreen extends StatefulWidget {
  final String maidId;

  const MaidDetailsScreen({
    super.key,
    required this.maidId,
  });

  @override
  State<MaidDetailsScreen> createState() => _MaidDetailsScreenState();
}

class _MaidDetailsScreenState extends State<MaidDetailsScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;
  late final Future<_WorkerDetailsData> _detailsFuture;
  final FavoritesProvider _favoritesProvider = FavoritesProvider.instance;
  AnimationController? _favoriteController;
  late Animation<double> _favoriteScaleAnimation;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = _favoritesProvider.isFavorited(widget.maidId);
    _favoritesProvider.addListener(_onFavoritesChanged);
    _scrollController.addListener(_onScroll);
    
    // Favorite icon animation
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _favoriteController!, curve: Curves.elasticOut),
    );
    if (_isFavorited) {
      _favoriteController!.value = 1.0;
    }
    
    _detailsFuture = _loadWorkerDetails(widget.maidId);
  }

  Future<_WorkerDetailsData> _loadWorkerDetails(String maidId) async {
    final results = await Future.wait([
      sl<GetWorkerByIdUseCase>()(maidId),
      sl<GetLanguagesUseCase>()(),
    ]);
    return _WorkerDetailsData(
      maid: results[0] as Maid?,
      languages: results[1] as List<Language>,
    );
  }

  /// Resolve worker `languagesIds` tokens to names from the Languages API.
  List<String> _resolveLanguageNames(
    List<String> languageIds,
    List<Language> catalog,
  ) {
    if (languageIds.isEmpty || catalog.isEmpty) return const [];
    return languageIds
        .map((id) => LanguageLookup.displayName(catalog, id))
        .where((name) => name.trim().isNotEmpty)
        .toList();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
        _isFavorited = _favoritesProvider.isFavorited(widget.maidId);
      });
    }
  }

  void _handleFavoriteTap() {
    _favoriteController!.forward().then((_) {
      _favoriteController!.reverse();
    });
    _favoritesProvider.toggleFavorite(widget.maidId);
  }

  @override
  void dispose() {
    _favoritesProvider.removeListener(_onFavoritesChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _favoriteController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final scrollThreshold = 250.0; // Show sticky header after scrolling past hero section
    
    final shouldShow = currentOffset > scrollThreshold;
    
    if (shouldShow != _showStickyHeader) {
      setState(() {
        _showStickyHeader = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('maid') ?? AppStrings.maid,
        notificationCount: 0,
        showBackButton: true,
      ),
      body: FutureBuilder<_WorkerDetailsData>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaidDetailsSkeleton();
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.maid == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    L10n.of(context)?.translate('maidNotFound') ?? AppStrings.maidNotFound,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppStrings.routeHome),
                    child: Text(L10n.of(context)?.translate('goHome') ?? AppStrings.goHome),
                  ),
                ],
              ),
            );
          }

          final details = snapshot.data!;
          final maid = details.maid!;
          final languages = details.languages;
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Section with Avatar, Rating, and Availability
                      _buildHeroSection(context, maid, languages)
                          .animate()
                          .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                          .scale(duration: 280.ms, curve: Curves.easeOutCubic),
                      
                      // Main Content
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Personal Information
                            _buildPersonalInfoSection(context, maid, languages)
                                .animate(delay: 100.ms)
                                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                            const SizedBox(height: 24),

                            // Specialties
                            _buildSpecialtiesSection(context, maid)
                                .animate(delay: 150.ms)
                                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                            const SizedBox(height: 24),

                            // Experience
                            _buildExperienceSection(context, maid)
                                .animate(delay: 200.ms)
                                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                            const SizedBox(height: 24),

                            // Health Certificate
                            _buildHealthCertificateSection(context, maid)
                                .animate(delay: 250.ms)
                                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                            const SizedBox(height: 24),

                            // Company Information - More compact
                            if (maid.companyName != null)
                              _buildCompanySection(context, maid)
                                  .animate(delay: 350.ms)
                                  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                            if (maid.companyName != null) const SizedBox(height: 24),

                            Builder(
                              builder: (context) {
                                final workerId = int.tryParse(maid.id);
                                if (workerId == null) {
                                  return const SizedBox.shrink();
                                }
                                return WorkerReviewsSection(workerId: workerId)
                                    .animate(delay: 380.ms)
                                    .fadeIn(
                                      duration: 280.ms,
                                      curve: Curves.easeOutCubic,
                                    );
                              },
                            ),
                            const SizedBox(height: 24),

                            _buildReportWorkerSection(context, maid)
                                .animate(delay: 400.ms)
                                .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                      ),
                    ),
                  ),
                  // Sticky Bottom Booking Bar
                  _buildStickyBookingBar(context, maid),
                ],
              ),
              // Sticky Top Bar with maid info
              if (_showStickyHeader) _buildStickyTopBar(context, maid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    Maid maid,
    List<Language> languages,
  ) {
    final l10n = L10n.of(context);
    final workerId = int.tryParse(maid.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              AppColors.gradientHaloCenter,
                              AppColors.gradientHaloEdge,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: AppColors.secondary,
                          child: ImageUtils.isValidImageUrl(maid.avatarUrl)
                              ? ClipOval(
                                  child: Image.network(
                                    maid.avatarUrl,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderAvatar(),
                                  ),
                                )
                              : _buildPlaceholderAvatar(),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _handleFavoriteTap,
                          child: AnimatedBuilder(
                            animation: _favoriteController!,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _favoriteScaleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _isFavorited
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isFavorited
                                            ? AppColors.primary.withOpacity(0.2)
                                            : AppColors.border.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isFavorited
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24,
                                    color: _isFavorited
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  maid.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: WorkerAvailabilityBadge(
                    maid: maid,
                    prominent: false,
                  ),
                ),
                if (workerId != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: WorkerRatingDisplay(
                        workerId: workerId,
                        starSize: 22,
                        alignment: MainAxisAlignment.center,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${maid.experienceYears} ${l10n?.translate('yearsExperience') ?? 'years experience'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                _buildNationalityAndLanguages(context, maid, languages),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationalityAndLanguages(
    BuildContext context,
    Maid maid,
    List<Language> languages,
  ) {
    final l10n = L10n.of(context);
    final languageNames = _resolveLanguageNames(maid.languages, languages);
    final nationality = maid.nationality?.trim();
    final hasNationality = nationality != null && nationality.isNotEmpty;
    final hasLanguages = languageNames.isNotEmpty;
    final hasAge = maid.age != null;

    if (!hasNationality && !hasLanguages && !hasAge) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (hasNationality)
            _buildProfileMetaChip(
              context,
              icon: Icons.flag_outlined,
              label: l10n?.translate('nationality') ?? 'Nationality',
              value: nationality,
            ),
          if (hasAge)
            _buildProfileMetaChip(
              context,
              icon: Icons.cake_outlined,
              label: l10n?.translate('age') ?? 'Age',
              value: '${maid.age} ${l10n?.translate('years') ?? 'years'}',
            ),
          if (hasLanguages)
            _buildProfileMetaChip(
              context,
              icon: Icons.language,
              label: l10n?.translate('languages') ?? 'Languages',
              value: languageNames.join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileMetaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Image.asset(
      'assets/images/worker_placeholder.png',
      width: 140,
      height: 140,
      fit: BoxFit.cover,
    );
  }

  Widget _buildSmallPlaceholderAvatar() {
    return Image.asset(
      'assets/images/worker_placeholder.png',
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }

  Widget _buildStickyTopBar(BuildContext context, Maid maid) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_showStickyHeader,
        child: AnimatedOpacity(
          opacity: _showStickyHeader ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Small Avatar
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.secondary,
                        child: ImageUtils.isValidImageUrl(maid.avatarUrl)
                            ? ClipOval(
                                child: Image.network(
                                  maid.avatarUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildSmallPlaceholderAvatar(),
                                ),
                              )
                            : _buildSmallPlaceholderAvatar(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            maid.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Builder(
                            builder: (context) {
                              final workerId = int.tryParse(maid.id);
                              if (workerId == null) {
                                return const SizedBox.shrink();
                              }
                              return SizedBox(
                                width: double.infinity,
                                child: WorkerRatingDisplay(
                                  workerId: workerId,
                                  starSize: 14,
                                  compact: true,
                                  alignment: MainAxisAlignment.center,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Favorite icon in sticky header
                    GestureDetector(
                      onTap: () => _handleFavoriteTap(),
                      child: AnimatedBuilder(
                        animation: _favoriteController!,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _favoriteScaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isFavorited
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 24,
                                color: _isFavorited
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceSection(BuildContext context, Maid maid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.work_outline,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = L10n.of(context);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.translate('experience') ?? AppStrings.experience,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${maid.experienceYears} ${maid.experienceYears == 1 ? (l10n?.translate('yearOfExperience') ?? 'year of professional cleaning experience') : (l10n?.translate('yearsOfExperience') ?? 'years of professional cleaning experience')}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySection(BuildContext context, Maid maid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final l10n = L10n.of(context);
            return Text(
              l10n?.translate('companyInformation') ?? 'Company Information',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            );
          },
        ),
        const SizedBox(height: 12), // Reduced spacing
        Container(
          padding: const EdgeInsets.all(16), // Reduced padding
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              // Company Name - Verified Icon - Rating (one line)
              if (maid.companyName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        maid.companyName!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    // Verified icon
                    Icon(
                      Icons.verified,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    // Rating
                    if (maid.companyRating != null) ...[
                      Icon(
                        Icons.star,
                        color: AppColors.primary, // Dusty Rose
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        maid.companyRating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
              // Location (below)
              if (maid.companyLocation != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      maid.companyLocation!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
              // View Company Profile Button
              if (maid.companyId != null) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.push(AppStrings.companyDetailsRoute(maid.companyId!));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                final l10n = L10n.of(context);
                                return Text(
                                  l10n?.translate('viewCompanyProfile') ?? 'View Company Profile',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(
    BuildContext context,
    Maid maid,
    List<Language> languages,
  ) {
    final l10n = L10n.of(context);
    final languageNames = _resolveLanguageNames(maid.languages, languages);
    final rows = <Widget>[];

    void addRow(Widget row) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 16));
      }
      rows.add(row);
    }

    final nationality = maid.nationality?.trim();
    if (nationality != null && nationality.isNotEmpty) {
      addRow(
        _buildInfoRow(
          context,
          icon: Icons.flag,
          label: l10n?.translate('nationality') ?? 'Nationality',
          value: nationality,
        ),
      );
    }

    if (maid.age != null) {
      addRow(
        _buildInfoRow(
          context,
          icon: Icons.cake,
          label: l10n?.translate('age') ?? 'Age',
          value: '${maid.age} ${l10n?.translate('years') ?? 'years'}',
        ),
      );
    }

    if (languageNames.isNotEmpty) {
      addRow(
        _buildInfoRow(
          context,
          icon: Icons.language,
          label: l10n?.translate('languages') ?? 'Languages',
          value: languageNames.join(', '),
        ),
      );
    }

    if (maid.healthCertificateExpiryDate != null) {
      addRow(
        _buildInfoRow(
          context,
          icon: Icons.event,
          label: l10n?.translate('healthCertificate') ?? 'Health Certificate',
          value:
              '${l10n?.translate('expires') ?? 'Expires'}: ${_formatDate(maid.healthCertificateExpiryDate!)}',
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.translate('personalInformation') ?? 'Personal Information',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 0.8,
            ),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildHealthCertificateSection(BuildContext context, Maid maid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shield,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                final l10n = L10n.of(context);
                return Text(
                  l10n?.translate('healthCertificate') ?? 'Health Certificate',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24), // Increased from 20 to 24 for emphasis
          decoration: BoxDecoration(
            color: maid.hasHealthCertificate
                ? AppColors.success.withOpacity(0.08) // Stronger green accent
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: maid.hasHealthCertificate
                  ? AppColors.success.withOpacity(0.4) // Stronger green border
                  : AppColors.border.withOpacity(0.5),
              width: maid.hasHealthCertificate ? 1.2 : 0.8, // Thicker border when valid
            ),
          ),
          child: Column(
            children: [
              // Health Certificate Status
              Row(
                children: [
                  Icon(
                    maid.hasHealthCertificate
                        ? Icons.verified
                        : Icons.error_outline,
                    color: maid.hasHealthCertificate
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final l10n = L10n.of(context);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.translate('status') ?? 'Status',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  maid.hasHealthCertificate
                                      ? (l10n?.translate('validCertificate') ?? 'Valid Certificate')
                                      : (l10n?.translate('noCertificate') ?? 'No Certificate'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: maid.hasHealthCertificate
                                            ? AppColors.success
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (maid.hasHealthCertificate) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n?.translate('verifiedBySitt') ?? 'Verified by Bareq',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                  // Expiry Date - Small under status
                                  if (maid.healthCertificateExpiryDate != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '${l10n?.translate('expires') ?? 'Expires'}: ${_formatDate(maid.healthCertificateExpiryDate!)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11, // Smaller text
                                          ),
                                    ),
                                  ],
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isRating = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRating
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isRating ? AppColors.primary : AppColors.accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSpecialtiesSection(BuildContext context, Maid maid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final l10n = L10n.of(context);
            return Text(
              l10n?.translate('specialties') ?? 'Specialties',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: maid.specialties.map((specialty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2), // Subtle Dusty Rose outline for selectable look
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.border.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cleaning_services,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    specialty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600, // Slightly bolder
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStickyBookingBar(BuildContext context, Maid maid) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reassurance microcopy
              Builder(
                builder: (context) {
                  final l10n = L10n.of(context);
                  return Text(
                    l10n?.translate('youWontBeChargedYet') ?? 'You won\'t be charged yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3), // Subtle glow
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                              onPressed: () {
                                context.push(AppStrings.bookingRoute(maid.id));
                              },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18), // Increased from 16
                    minimumSize: const Size(0, 60), // Increased from 56
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0, // Remove default elevation, using custom shadow
                  ),
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 22,
                    color: Colors.white,
                  ),
                  label: Builder(
                    builder: (context) {
                      final l10n = L10n.of(context);
                      return Text(
                        l10n?.translate('bookNow') ?? AppStrings.bookNow,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportWorkerSection(BuildContext context, Maid maid) {
    final workerId = int.tryParse(maid.id);
    if (workerId == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(Icons.report_outlined, color: Colors.red.shade400),
        title: Text(
          L10n.translate(context, 'reportWorker'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
        onTap: () {
          context.push(
            AppStrings.routeCreateReport,
            extra: CreateReportArgs(
              targetType: ReportTargetType.worker,
              targetId: workerId,
              targetName: maid.name,
              returnRoute: AppStrings.maidDetailsRoute(maid.id),
            ),
          );
        },
      ),
    );
  }
}

