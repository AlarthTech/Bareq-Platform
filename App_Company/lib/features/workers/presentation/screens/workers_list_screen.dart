import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/presentation/widgets/paged_list_footer.dart';
import '../../../../core/widgets/main_tab_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/saas/saas_card.dart';
import '../../../../core/widgets/saas/worker_operational_badge.dart';
import '../../../../core/utils/url_helper.dart';
import '../bloc/worker_bloc.dart';
import '../bloc/worker_event.dart';
import '../bloc/worker_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';
import '../../domain/entities/worker_entity.dart';
import '../../../worker_reviews/domain/entities/worker_rating_summary.dart';
import '../../../worker_reviews/domain/usecases/get_company_worker_summaries.dart';
import '../../../worker_reviews/presentation/widgets/review_list_item.dart';
import '../widgets/assign_work_type_sheet.dart';
import '../widgets/edit_worker_sheet.dart';
import '../widgets/worker_list_action_button.dart';

enum _WorkerFilter { all, available, unavailable, certExpired }

class WorkersListScreen extends StatefulWidget {
  const WorkersListScreen({super.key});

  @override
  State<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends State<WorkersListScreen>
    with SingleTickerProviderStateMixin {
  _WorkerFilter _filter = _WorkerFilter.all;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  Map<int, WorkerRatingSummary> _ratingSummaries = {};

  late final AnimationController _fabIconController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onWorkersScroll);
    _fabIconController = AnimationController(
      vsync: this,
      duration: AnimationConstants.microInteraction,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkers());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onWorkersScroll);
    _scrollController.dispose();
    _fabIconController.dispose();
    super.dispose();
  }

  void _onWorkersScroll() {
    if (!_scrollController.hasClients) return;
    final workerState = context.read<WorkerBloc>().state;
    if (workerState is! WorkersLoaded ||
        workerState.isLoadingMore ||
        !workerState.hasNextPage) {
      return;
    }
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 240) {
      return;
    }
    final cs = context.read<CompanyBloc>().state;
    if (cs is CompanyLoaded && cs.companies.isNotEmpty) {
      context.read<WorkerBloc>().add(
            LoadMoreWorkersEvent(cs.activeCompanyId!),
          );
    }
  }

  void _loadWorkers() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(authState.user.id));
    }
    final companyState = context.read<CompanyBloc>().state;
    if (companyState is CompanyLoaded && companyState.companies.isNotEmpty) {
      final companyId = companyState.activeCompanyId!;
      context.read<WorkerBloc>().add(GetWorkersEvent(companyId));
      _loadRatingSummaries(companyId);
    }
  }

  Future<void> _loadRatingSummaries(int companyId) async {
    final result = await getIt<GetCompanyWorkerSummariesUseCase>()(companyId);
    if (!mounted) return;
    result.fold(
      (_) {},
      (summaries) => setState(() {
        _ratingSummaries = {for (final s in summaries) s.workerId: s};
      }),
    );
  }

  bool _isCertExpired(WorkerEntity w) {
    final d = w.healthCertificateExpiryDate;
    if (d == null) return false;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return d.isBefore(today);
  }

  List<WorkerEntity> _applyFilters(List<WorkerEntity> all) {
    Iterable<WorkerEntity> list = all;
    switch (_filter) {
      case _WorkerFilter.all:
        break;
      case _WorkerFilter.available:
        list = list.where((w) => w.isAvailable);
        break;
      case _WorkerFilter.unavailable:
        list = list.where((w) => !w.isAvailable);
        break;
      case _WorkerFilter.certExpired:
        list = list.where(_isCertExpired);
        break;
    }
    final q = _searchQuery.trim();
    if (q.isNotEmpty) {
      list = list.where((w) => w.fullName.contains(q));
    }
    return list.toList();
  }

  Future<void> _openAddWorker() async {
    final created = await context.push<bool>(AppRoutes.workersAdd);
    if (created == true && mounted) {
      _loadWorkers();
    }
  }

  void _onFabPressed() {
    _fabIconController.forward().then((_) {
      _fabIconController.reverse();
      if (mounted) _openAddWorker();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacing16,
            AppTheme.spacing8,
            AppTheme.spacing16,
            AppTheme.spacing24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تصفية القائمة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              _FilterChipsRow(
                filter: _filter,
                onChanged: (f) {
                  setState(() => _filter = f);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainTabScaffold(
      title: 'العاملات',
      subtitle: 'إدارة العاملات',
      fabWithDefaultDecoration: false,
      currentNavIndex: AppRoutes.navWorkers,
      actions: [
        IconButton(
          tooltip: 'تصفية',
          icon: const Icon(Icons.tune_rounded),
          onPressed: _showFilterSheet,
        ),
      ],
      floatingActionButton: _WorkersGradientFab(
        onPressed: _onFabPressed,
        rotation: _fabIconController,
      ),
      body: BlocListener<CompanyBloc, CompanyState>(
        listenWhen: (prev, curr) =>
            curr is CompanyLoaded &&
            curr.companies.isNotEmpty &&
            (prev is! CompanyLoaded || prev.companies.isEmpty),
        listener: (context, state) {
          if (state is CompanyLoaded && state.companies.isNotEmpty) {
            final companyId = state.activeCompanyId!;
            context.read<WorkerBloc>().add(GetWorkersEvent(companyId));
            _loadRatingSummaries(companyId);
          }
        },
        child: BlocBuilder<WorkerBloc, WorkerState>(
            builder: (context, state) {
              if (state is WorkerLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacing16,
                    AppTheme.spacing8,
                    AppTheme.spacing16,
                    AppTheme.spacing16,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spacing12),
                    child: _WorkerCardSkeleton(),
                  ),
                );
              }

              if (state is WorkerError) {
                return ErrorStateWidget(
                  message: state.message,
                  onRetry: _loadWorkers,
                );
              }

              if (state is WorkersLoaded) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacing16,
                        0,
                        AppTheme.spacing16,
                        AppTheme.spacing8,
                      ),
                      child: TextField(
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم…',
                          prefixIcon: const Icon(Icons.search, size: 22),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing16,
                            vertical: AppTheme.spacing12,
                          ),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                      child: _FilterChipsRow(
                        filter: _filter,
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Expanded(
                      child: _buildWorkerList(state),
                    ),
                  ],
                );
              }

              return const EmptyStateWidget(message: 'لا توجد بيانات');
            },
          ),
      ),
    );
  }

  Widget _buildWorkerList(WorkersLoaded loaded) {
    final workers = loaded.workers;
    if (workers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _WorkersEmptyIllustration(),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'لا توجد عاملات حالياً',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.gray500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              FilledButton.icon(
                onPressed: _openAddWorker,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
                label: const Text('إضافة عاملة'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24,
                    vertical: AppTheme.spacing12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _applyFilters(workers);
    if (filtered.isEmpty) {
      return EmptyStateWidget(
        message: 'لا توجد عاملات مطابقة للفلتر',
        icon: Icons.filter_alt_off_outlined,
        action: TextButton(
          onPressed: () => setState(() {
            _filter = _WorkerFilter.all;
            _searchQuery = '';
          }),
          child: const Text('إعادة ضبط الفلتر'),
        ),
      );
    }

    return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16,
          0,
          AppTheme.spacing16,
          80,
        ),
        itemCount: filtered.length +
            ((loaded.hasNextPage || loaded.isLoadingMore) ? 1 : 0),
        cacheExtent: 400,
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return PagedListFooter(
              isLoadingMore: loaded.isLoadingMore,
              hasNextPage: loaded.hasNextPage,
            );
          }
          final worker = filtered[index];
          final ratingSummary = _ratingSummaries[worker.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: _WorkerListCard(
              worker: worker,
              certExpired: _isCertExpired(worker),
              ratingSummary: ratingSummary,
              index: index,
              onWorkersUpdated: _loadWorkers,
            ),
          )
              .animate(delay: (index * AnimationConstants.staggerMs).ms)
              .fadeIn(
                duration: AnimationConstants.fadeIn,
                curve: AnimationConstants.fadeInCurve,
              );
        },
      );
  }
}

class _WorkerListCard extends StatelessWidget {
  const _WorkerListCard({
    required this.worker,
    required this.certExpired,
    required this.index,
    required this.onWorkersUpdated,
    this.ratingSummary,
  });

  final WorkerEntity worker;
  final bool certExpired;
  final int index;
  final VoidCallback onWorkersUpdated;
  final WorkerRatingSummary? ratingSummary;

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return _WorkerCard(
      worker: worker,
      certExpired: certExpired,
      ratingSummary: ratingSummary,
      onTapView: () {
        context.push(
          AppRoutes.workerDetail(worker.id),
          extra: worker,
        );
      },
      onAssignWorkType: () => AssignWorkTypeSheet.show(context, worker: worker),
      onEditWorker: () async {
        final updated = await EditWorkerSheet.show(context, worker: worker);
        if (updated == true && context.mounted) {
          onWorkersUpdated();
        }
      },
      onToggleActive: () {
        _snack(
          context,
          worker.isActive ? 'تعطيل العاملة — قريباً' : 'تفعيل العاملة — قريباً',
        );
      },
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.filter,
    required this.onChanged,
  });

  final _WorkerFilter filter;
  final ValueChanged<_WorkerFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = <(_WorkerFilter, String)>[
      (_WorkerFilter.all, 'الكل'),
      (_WorkerFilter.available, 'متاحة'),
      (_WorkerFilter.unavailable, 'غير متاحة'),
      (_WorkerFilter.certExpired, 'شهادة منتهية'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacing8),
        itemBuilder: (context, i) {
          final (f, label) = items[i];
          final selected = filter == f;
          return AnimatedContainer(
            duration: AnimationConstants.microInteraction,
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(f),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: AnimatedContainer(
                  duration: AnimationConstants.microInteraction,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryTeal : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    boxShadow: selected ? null : AppTheme.softShadow,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? Colors.white : AppTheme.gray600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.worker,
    required this.certExpired,
    required this.onTapView,
    required this.onAssignWorkType,
    required this.onEditWorker,
    required this.onToggleActive,
    this.ratingSummary,
  });

  final WorkerEntity worker;
  final bool certExpired;
  final VoidCallback onTapView;
  final VoidCallback onAssignWorkType;
  final VoidCallback onEditWorker;
  final VoidCallback onToggleActive;
  final WorkerRatingSummary? ratingSummary;

  @override
  Widget build(BuildContext context) {
    final w = worker;
    final imageUrl = resolveApiUrl(w.profileImage);

    return SaasCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTapView,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Row(
                children: [
                  WorkerOperationalBadge(worker: w, certificateExpired: certExpired),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          w.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${w.experienceYears} سنوات خبرة',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.gray500,
                                fontSize: 12,
                              ),
                        ),
                        if (ratingSummary != null && ratingSummary!.hasReviews) ...[
                          const SizedBox(height: 4),
                          WorkerRatingBadge(
                            averageRating: ratingSummary!.averageRating,
                            totalReviews: ratingSummary!.totalReviews,
                            onTap: () => openWorkerReviews(
                              context,
                              workerId: w.id,
                              workerName: w.fullName,
                              profileImage: w.profileImage,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  _CompactAvatar(url: imageUrl, name: w.fullName),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: WorkerListActionButton(
                  label: 'ربط خدمة',
                  icon: Icons.link_rounded,
                  color: AppTheme.secondaryBlue,
                  onPressed: onAssignWorkType,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: WorkerListActionButton(
                  label: 'تعديل',
                  icon: Icons.edit_outlined,
                  color: AppTheme.primaryTeal,
                  filled: true,
                  onPressed: onEditWorker,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: WorkerListActionButton(
                  label: w.isActive ? 'تعطيل' : 'تفعيل',
                  icon: w.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: w.isActive ? AppTheme.gray600 : const Color(0xFF16A34A),
                  onPressed: onToggleActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactAvatar extends StatelessWidget {
  const _CompactAvatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _AvatarFallback(initial: initial),
              errorWidget: (_, __, ___) => _AvatarFallback(initial: initial),
            )
          : _AvatarFallback(initial: initial),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.primaryTeal.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppTheme.primaryTeal,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class _WorkerCardSkeleton extends StatelessWidget {
  const _WorkerCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SaasCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing12,
      ),
      child: Row(
        children: [
          LoadingShimmerWidget(
            width: 56,
            height: 22,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          const Spacer(),
          LoadingShimmerWidget(
            width: 120,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(width: 10),
          LoadingShimmerWidget(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(22),
          ),
        ],
      ),
    );
  }
}

class _WorkersEmptyIllustration extends StatelessWidget {
  const _WorkersEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryTeal.withValues(alpha: 0.12),
            AppTheme.secondaryBlue.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Icon(
        Icons.groups_outlined,
        size: 52,
        color: AppTheme.primaryTeal.withValues(alpha: 0.65),
      ),
    );
  }
}

class _WorkersGradientFab extends StatelessWidget {
  const _WorkersGradientFab({
    required this.onPressed,
    required this.rotation,
  });

  final VoidCallback onPressed;
  final Animation<double> rotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryTeal,
            Color(0xFF0D9488),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.42),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: RotationTransition(
                turns: rotation,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
