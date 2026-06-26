import 'package:flutter/material.dart';
import '../../domain/entities/maid.dart';
import '../../../ratings/domain/entities/rating_summary.dart';
import '../../../ratings/presentation/widgets/rating_badge.dart';
import '../../../ratings/presentation/widgets/worker_card_rating.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/favorites/favorites_provider.dart';
import '../../../../core/utils/image_utils.dart';
import 'maid_availability_badge.dart';
import 'maid_company_city_row.dart';

/// Reusable maid card widget
/// Displays maid information in a horizontal card format
/// Can be used in horizontal lists or grid layouts
class MaidCard extends StatefulWidget {
  final Maid maid;
  final VoidCallback? onTap;
  final bool emphasizeRating;
  final bool isGridLayout;
  final WorkerRatingSummary? workerRatingSummary;
  /// When true, always use [RatingBadge] (company worker list); missing
  /// summary means no reviews, not legacy [maid.rating].
  final bool showRatingFromSummary;
  /// Green badge for available-workers list; neutral for top-rated when not today.
  final bool prominentAvailabilityBadge;

  const MaidCard({
    super.key,
    required this.maid,
    this.onTap,
    this.emphasizeRating = false,
    this.isGridLayout = false,
    this.workerRatingSummary,
    this.showRatingFromSummary = false,
    this.prominentAvailabilityBadge = true,
  });

  @override
  State<MaidCard> createState() => _MaidCardState();
}

class _MaidCardState extends State<MaidCard> with TickerProviderStateMixin {
  late AnimationController _tapController;
  AnimationController? _favoriteController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _favoriteScaleAnimation;
  final FavoritesProvider _favoritesProvider = FavoritesProvider.instance;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = _favoritesProvider.isFavorited(widget.maid.id);
    _favoritesProvider.addListener(_onFavoritesChanged);

    // Tap animation
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );

    // Favorite icon animation
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _favoriteController!, curve: Curves.easeOut),
    );
    if (_isFavorited) {
      _favoriteController!.value = 1.0;
    }
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
        _isFavorited = _favoritesProvider.isFavorited(widget.maid.id);
      });
    }
  }

  void _handleFavoriteTap() {
    _favoriteController!.forward().then((_) {
      _favoriteController!.reverse();
    });
    _favoritesProvider.toggleFavorite(widget.maid.id);
  }

  @override
  void dispose() {
    _favoritesProvider.removeListener(_onFavoritesChanged);
    _tapController.dispose();
    _favoriteController?.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapController.forward().then((_) {
      _tapController.reverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isGrid = widget.isGridLayout;
    final avatarRadius = isGrid ? 28.0 : 32.0;
    final avatarSize = avatarRadius * 2;
    final cardPadding = isGrid ? 5.0 : 6.0;
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: _tapController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.isGridLayout ? double.infinity : 152,
                margin:
                    widget.isGridLayout
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.5),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.border.withOpacity(
                        0.05 + _shadowAnimation.value,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Avatar with Lavender ring and Favorite icon
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.border.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: AppColors.secondary,
                            child:
                                ImageUtils.isValidImageUrl(widget.maid.avatarUrl)
                                    ? ClipOval(
                                      child: Image.network(
                                        widget.maid.avatarUrl,
                                        width: avatarSize,
                                        height: avatarSize,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildPlaceholderAvatar(
                                                  avatarSize,
                                                ),
                                      ),
                                    )
                                    : _buildPlaceholderAvatar(avatarSize),
                          ),
                        ),
                      ),
                      // Favorite icon in top-right corner
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
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        _isFavorited
                                            ? AppColors.primary.withOpacity(0.1)
                                            : AppColors.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            _isFavorited
                                                ? AppColors.primary.withOpacity(
                                                  0.2,
                                                )
                                                : AppColors.border.withOpacity(
                                                  0.2,
                                                ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isFavorited
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color:
                                        _isFavorited
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
                  SizedBox(height: isGrid ? 2 : 4),

                  // Name
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      widget.maid.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: isGrid ? 12 : 13,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isGrid ? 2 : 2),

                  Center(
                    child: WorkerAvailabilityBadge(
                      maid: widget.maid,
                      prominent: widget.prominentAvailabilityBadge,
                      compact: true,
                    ),
                  ),
                  if (!isGrid) MaidCompanyCityRow(maid: widget.maid, compact: true),
                  SizedBox(height: isGrid ? 1 : 2),

                  // Rating
                  Center(child: _buildRating(compact: true)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRating({bool compact = false}) {
    if (widget.showRatingFromSummary || widget.workerRatingSummary != null) {
      return RatingBadge(
        summary: widget.workerRatingSummary ??
            WorkerRatingSummary(
              workerId: int.tryParse(widget.maid.id) ?? 0,
              averageRating: 0,
              totalReviews: 0,
            ),
        compact: true,
        dense: compact,
      );
    }

    final workerId = int.tryParse(widget.maid.id);
    if (workerId == null) return const SizedBox.shrink();

    return WorkerCardRating(workerId: workerId, dense: compact);
  }

  Widget _buildPlaceholderAvatar(double size) {
    return Image.asset(
      'assets/images/worker_placeholder.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
