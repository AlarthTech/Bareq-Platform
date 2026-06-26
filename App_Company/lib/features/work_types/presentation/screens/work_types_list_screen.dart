import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/presentation/widgets/paged_list_footer.dart';
import '../../../../core/widgets/main_tab_scaffold.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/work_type_display.dart';
import '../../../../core/utils/work_shift_label.dart';
import '../bloc/work_type_bloc.dart';
import '../bloc/work_type_event.dart';
import '../bloc/work_type_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';
import '../widgets/work_type_form_sheet.dart';
import '../../domain/entities/work_type_entity.dart';

enum _ShiftSection { monthly, morning, evening }

class WorkTypesListScreen extends StatefulWidget {
  const WorkTypesListScreen({super.key});

  @override
  State<WorkTypesListScreen> createState() => _WorkTypesListScreenState();
}

class _WorkTypesListScreenState extends State<WorkTypesListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onWorkTypesScroll);
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(authState.user.id));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cs = context.read<CompanyBloc>().state;
      if (cs is CompanyLoaded && cs.companies.isNotEmpty) {
        context.read<WorkTypeBloc>().add(GetWorkTypesEvent(cs.activeCompanyId!));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onWorkTypesScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onWorkTypesScroll() {
    if (!_scrollController.hasClients) return;
    final wtState = context.read<WorkTypeBloc>().state;
    if (wtState is! WorkTypesLoaded ||
        wtState.isLoadingMore ||
        !wtState.hasNextPage) {
      return;
    }
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 240) {
      return;
    }
    final cs = context.read<CompanyBloc>().state;
    if (cs is CompanyLoaded && cs.companies.isNotEmpty) {
      context.read<WorkTypeBloc>().add(
            LoadMoreWorkTypesEvent(cs.activeCompanyId!),
          );
    }
  }

  void _loadWorkTypes() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(authState.user.id));
    }
    final cs = context.read<CompanyBloc>().state;
    if (cs is CompanyLoaded && cs.companies.isNotEmpty) {
      context.read<WorkTypeBloc>().add(GetWorkTypesEvent(cs.activeCompanyId!));
    }
  }

  void _refreshWorkTypes() {
    final cs = context.read<CompanyBloc>().state;
    if (cs is CompanyLoaded && cs.companies.isNotEmpty) {
      context.read<WorkTypeBloc>().add(GetWorkTypesEvent(cs.activeCompanyId!));
    }
  }

  Future<void> _openAddService() async {
    final added = await context.push<bool>(AppRoutes.workTypesAdd);
    if (!context.mounted) return;
    if (added == true) _refreshWorkTypes();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listenWhen: (prev, curr) =>
          curr is CompanyLoaded &&
          curr.companies.isNotEmpty &&
          (prev is! CompanyLoaded || prev.companies.isEmpty),
      listener: (context, state) {
        if (state is CompanyLoaded && state.companies.isNotEmpty) {
          context.read<WorkTypeBloc>().add(GetWorkTypesEvent(state.activeCompanyId!));
        }
      },
      child: BlocListener<WorkTypeBloc, WorkTypeState>(
        listener: (context, state) {
          if (state is WorkTypeDeleted || state is WorkTypeCreated || state is WorkTypeUpdated) {
            _refreshWorkTypes();
          }
          if (state is WorkTypeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.dangerRed),
            );
          }
        },
        child: MainTabScaffold(
          title: 'الخدمات والورديات',
          subtitle: 'إدارة الخدمات والأوقات',
          currentNavIndex: AppRoutes.navWorkTypes,
          aboveBottomNav: _StickyAddShiftBar(
            onPressed: () {
              _openAddService();
            },
          ),
          body: BlocBuilder<WorkTypeBloc, WorkTypeState>(
            buildWhen: (prev, curr) {
              if (curr is WorkTypesLoaded) return true;
              if (curr is WorkTypeLoading) return true;
              if (curr is WorkTypeError) return true;
              return false;
            },
            builder: (context, state) {
              if (state is WorkTypeLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  itemCount: 5,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spacing12),
                    child: _WorkTypeCardSkeleton(),
                  ),
                );
              }

              if (state is WorkTypeError) {
                return ErrorStateWidget(
                  message: state.message,
                  onRetry: _loadWorkTypes,
                );
              }

              if (state is WorkTypesLoaded) {
                if (state.workTypes.isEmpty) {
                  return const _EmptyWorkTypes();
                }

                final grouped = _groupBySection(state.workTypes);
                var animIndex = 0;
                var sectionIndex = 0;
                final children = <Widget>[];

                for (final entry in grouped.entries) {
                  if (entry.value.isEmpty) continue;
                  final isFirstSection = sectionIndex++ == 0;
                  children.add(
                    _SectionHeader(
                      title: _sectionTitle(entry.key),
                      isFirst: isFirstSection,
                    ),
                  );
                  for (final wt in entry.value) {
                    final idx = animIndex++;
                    children.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                        child: _WorkTypeCard(
                          workType: wt,
                          index: idx,
                          onTap: () => _showDetailSheet(context, wt),
                          onEdit: () => _showEditSheet(context, wt),
                          onDisable: () => _snack(context, 'تعطيل الخدمة — قريباً'),
                          onDelete: () => _confirmDelete(context, wt),
                        ),
                      ),
                    );
                  }
                }

                if (state.hasNextPage || state.isLoadingMore) {
                  children.add(
                    PagedListFooter(
                      isLoadingMore: state.isLoadingMore,
                      hasNextPage: state.hasNextPage,
                    ),
                  );
                }

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacing16,
                    AppTheme.spacing8,
                    AppTheme.spacing16,
                    28,
                  ),
                  children: children,
                );
              }

              return const Center(child: Text('لا توجد بيانات'));
            },
          ),
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(BuildContext context, WorkTypeEntity wt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الخدمة؟'),
        content: Text('سيتم حذف «${wt.name}» نهائياً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<WorkTypeBloc>().add(DeleteWorkTypeEvent(wt.id));
    }
  }

  void _showEditSheet(BuildContext context, WorkTypeEntity wt) {
    final workTypeBloc = context.read<WorkTypeBloc>();
    var submitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: workTypeBloc,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return BlocListener<WorkTypeBloc, WorkTypeState>(
                listener: (context, state) {
                  if (state is WorkTypeError) {
                    setModalState(() => submitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppTheme.dangerRed,
                      ),
                    );
                  } else if (state is WorkTypeUpdated) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث التصنيف بنجاح')),
                    );
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  child: WorkTypeFormSheet(
                    initial: wt,
                    isSubmitting: submitting,
                    submitLabel: 'تحديث التصنيف',
                    onSubmit: ({
                      required name,
                      required isMonthly,
                      required price,
                      startTime,
                      endTime,
                    }) {
                      setModalState(() => submitting = true);
                      context.read<WorkTypeBloc>().add(
                            UpdateWorkTypeEvent(
                              workTypeId: wt.id,
                              name: name,
                              isMonthly: isMonthly,
                              price: price,
                              isActive: wt.isActive,
                              startTime: startTime,
                              endTime: endTime,
                            ),
                          );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDetailSheet(BuildContext context, WorkTypeEntity wt) {
    final schedule = formatWorkTypeSchedule(wt);
    final tag = workShiftTag(
      isOvernight: false,
      startTime: wt.startTime,
      isMonthly: wt.isMonthly,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              wt.name,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (schedule != null) ...[
              const SizedBox(height: 8),
              Text(
                schedule,
                style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(color: AppTheme.gray600),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              formatWorkTypePrice(wt),
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _StatusBadge(active: wt.isActive),
                _ModeBadge(isMonthly: wt.isMonthly),
                if (!wt.isMonthly)
                  Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Map<_ShiftSection, List<WorkTypeEntity>> _groupBySection(List<WorkTypeEntity> all) {
  final monthly = <WorkTypeEntity>[];
  final morning = <WorkTypeEntity>[];
  final evening = <WorkTypeEntity>[];

  for (final wt in all) {
    if (wt.isMonthly) {
      monthly.add(wt);
      continue;
    }
    final tag = workShiftTag(
      isOvernight: false,
      startTime: wt.startTime,
      isMonthly: wt.isMonthly,
    );
    if (tag == 'صباحية') {
      morning.add(wt);
    } else {
      evening.add(wt);
    }
  }

  return {
    _ShiftSection.monthly: monthly,
    _ShiftSection.morning: morning,
    _ShiftSection.evening: evening,
  };
}

String _sectionTitle(_ShiftSection s) {
  switch (s) {
    case _ShiftSection.monthly:
      return 'الدوام الشهري';
    case _ShiftSection.morning:
      return 'الصباحية';
    case _ShiftSection.evening:
      return 'المسائية';
  }
}

/// Sticky above bottom nav — primary add action for shifts / services.
class _StickyAddShiftBar extends StatelessWidget {
  const _StickyAddShiftBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceBackground,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceBackground,
          border: Border(
            top: BorderSide(color: AppTheme.gray200.withValues(alpha: 0.9)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing12,
              AppTheme.spacing16,
              AppTheme.spacing12,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  '+ إضافة خدمة',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isFirst});

  final String title;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? AppTheme.spacing4 : AppTheme.spacing20,
        bottom: AppTheme.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isFirst) ...[
            const Divider(height: 1, thickness: 1, color: AppTheme.gray200),
            const SizedBox(height: AppTheme.spacing16),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: 10),
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.gray700,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkTypeCard extends StatefulWidget {
  const _WorkTypeCard({
    required this.workType,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDisable,
    required this.onDelete,
  });

  final WorkTypeEntity workType;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDisable;
  final VoidCallback onDelete;

  @override
  State<_WorkTypeCard> createState() => _WorkTypeCardState();
}

class _WorkTypeCardState extends State<_WorkTypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final wt = widget.workType;
    final schedule = formatWorkTypeSchedule(wt);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          splashColor: AppTheme.primaryTeal.withValues(alpha: 0.08),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              color: Colors.white,
              border: Border.all(color: AppTheme.gray200),
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing16,
                AppTheme.spacing12,
                AppTheme.spacing4,
                AppTheme.spacing12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                wt.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      height: 1.25,
                                      color: AppTheme.gray900,
                                    ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            _ModeBadge(isMonthly: wt.isMonthly),
                            const SizedBox(width: AppTheme.spacing8),
                            _StatusBadge(active: wt.isActive),
                          ],
                        ),
                        if (schedule != null) ...[
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            schedule,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.gray600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          formatWorkTypePrice(wt),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                height: 1.15,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: AppTheme.gray600),
                    tooltip: 'إجراءات',
                    onPressed: () => _showActionMenu(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: (widget.index * AnimationConstants.staggerMs).ms)
        .fadeIn(duration: AnimationConstants.fadeIn, curve: AnimationConstants.fadeInCurve);
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: AppTheme.gray800),
                title: const Text('تعديل'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.toggle_off_outlined, color: AppTheme.gray800),
                title: const Text('تعطيل'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDisable();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed),
                title: Text('حذف', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.isMonthly});

  final bool isMonthly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isMonthly
            ? AppTheme.secondaryBlue.withValues(alpha: 0.12)
            : AppTheme.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: isMonthly ? AppTheme.secondaryBlue : AppTheme.primaryTeal,
        ),
      ),
      child: Text(
        isMonthly ? 'شهري' : 'يومي',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isMonthly ? AppTheme.secondaryBlue : AppTheme.primaryTeal,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppTheme.successGreen : AppTheme.gray500,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            active ? 'نشطة' : 'غير نشطة',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _WorkTypeCardSkeleton extends StatelessWidget {
  const _WorkTypeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LoadingShimmerWidget(
                      height: 18,
                      width: 160,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const Spacer(),
                    LoadingShimmerWidget(
                      height: 24,
                      width: 56,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                LoadingShimmerWidget(
                  height: 14,
                  width: 120,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AppTheme.spacing8),
                LoadingShimmerWidget(
                  height: 22,
                  width: 100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing4),
          LoadingShimmerWidget(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkTypes extends StatelessWidget {
  const _EmptyWorkTypes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
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
                Icons.schedule_rounded,
                size: 48,
                color: AppTheme.primaryTeal.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'لا توجد خدمات حالياً',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.gray600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'استخدم زر الإضافة أدناه لإنشاء وردية جديدة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

