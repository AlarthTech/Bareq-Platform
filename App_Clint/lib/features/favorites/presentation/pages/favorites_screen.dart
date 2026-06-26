import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../home/domain/entities/maid.dart';
import '../../../home/domain/usecases/get_favorite_maids_usecase.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/presentation/widgets/maid_card.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/favorites/favorites_provider.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bottom_nav_bar.dart';
import '../widgets/skeleton/favorites_skeleton.dart';
import '../../../../core/widgets/common/app_empty_state.dart';

/// Favorites Screen — saved workers (maids) only.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesProvider _favoritesProvider = FavoritesProvider.instance;
  List<Maid> _favoriteMaids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _favoritesProvider.addListener(_onFavoritesChanged);
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoritesProvider.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final favoriteMaidIds = _favoritesProvider.favoriteMaidIds;
    final maids = await sl<GetFavoriteMaidsUseCase>()(favoriteMaidIds);

    if (!mounted) return;

    setState(() {
      _favoriteMaids = maids;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('myFavorites') ?? AppStrings.navFavorites,
      ),
      body:
          _isLoading
              ? const FavoritesSkeleton()
              : _favoriteMaids.isEmpty
              ? _buildEmptyMaids(context)
              : _buildMaidsGrid(context),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildMaidsGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.12,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _favoriteMaids.length,
      itemBuilder: (context, index) {
        final maid = _favoriteMaids[index];
        return MaidCard(
          maid: maid,
          isGridLayout: true,
          prominentAvailabilityBadge: false,
          onTap: () => context.push(AppStrings.maidDetailsRoute(maid.id)),
        );
      },
    );
  }

  Widget _buildEmptyMaids(BuildContext context) {
    final l10n = L10n.of(context);
    return AppEmptyState(
      icon: Icons.favorite_border,
      title: l10n?.translate('noFavoritesYet') ?? 'No Favorites Yet',
      subtitle:
          l10n?.translate('startAddingFavorites') ??
          'Start adding workers to your favorites',
      actionLabel: l10n?.translate('exploreMaids') ?? 'Explore Maids',
      onAction: () => context.go(AppStrings.routeHome),
    );
  }
}
