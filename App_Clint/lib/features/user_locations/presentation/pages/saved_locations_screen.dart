import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/pagination/pagination_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/failure_ui.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/app_empty_state.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/delete_user_location_usecase.dart';
import '../../domain/usecases/get_my_locations_page_usecase.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<UserLocation> _locations = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = PaginationConstants.defaultPage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollNearEnd);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollNearEnd);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollNearEnd() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      _load(reset: false);
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      if (_loadingMore) return;
      setState(() {
        _loading = true;
        _error = null;
        _currentPage = PaginationConstants.defaultPage;
        _hasMore = true;
        _locations = [];
      });
    } else {
      if (_loading || _loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    final page =
        reset ? PaginationConstants.defaultPage : _currentPage + 1;

    final result = await sl<GetMyLocationsPageUseCase>()(
      page: page,
      pageSize: PaginationConstants.defaultPageSize,
    );

    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _loadingMore = false;
        _error = failureMessage(context, f);
      }),
      (paged) => setState(() {
        if (reset) {
          _locations = paged.items;
        } else {
          final ids = _locations.map((l) => l.id).toSet();
          _locations.addAll(
            paged.items.where((l) => ids.add(l.id)),
          );
        }
        _currentPage = page;
        _hasMore = paged.hasNextPage;
        _loading = false;
        _loadingMore = false;
      }),
    );
  }

  Future<void> _deleteLocation(UserLocation loc) async {
    final l10n = L10n.of(context);
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(l10n?.translate('deleteLocation') ?? 'Delete location?'),
                content: Text(loc.locationName),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n?.translate('cancel') ?? 'Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n?.translate('delete') ?? 'Delete'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!ok) return;

    final result = await sl<DeleteUserLocationUseCase>()(loc.id);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureMessage(context, f)),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => _load(reset: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('savedLocations') ?? 'Saved locations',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppStrings.routeAddLocation);
          _load(reset: true);
        },
        icon: const Icon(Icons.add_location_alt),
        label: Text(l10n?.translate('addLocation') ?? 'Add location'),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _locations.isEmpty
              ? AppEmptyState(
                icon: Icons.error_outline,
                title: l10n?.translate('error') ?? 'Error',
                subtitle: _error!,
                actionLabel: l10n?.translate('retry') ?? 'Retry',
                onAction: () => _load(reset: true),
              )
              : _locations.isEmpty
              ? AppEmptyState(
                icon: Icons.place_outlined,
                title:
                    l10n?.translate('noSavedLocationsTitle') ??
                    'No saved locations',
                subtitle:
                    l10n?.translate('noSavedLocationsHint') ??
                    'Add an address to speed up booking.',
                actionLabel: l10n?.translate('addLocation') ?? 'Add location',
                onAction: () async {
                  await context.push(AppStrings.routeAddLocation);
                  _load(reset: true);
                },
              )
              : RefreshIndicator(
                onRefresh: () => _load(reset: true),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _locations.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= _locations.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final loc = _locations[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.place,
                          color: AppColors.primary,
                        ),
                        title: Text(loc.locationName),
                        subtitle: Text(
                          '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _deleteLocation(loc),
                        ),
                        onTap: () async {
                          await context.push(
                            AppStrings.editLocationRoute(loc.id.toString()),
                            extra: loc,
                          );
                          _load(reset: true);
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
