import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/booking_report_constants.dart';
import '../../../../core/presentation/widgets/paged_list_footer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../state/company_booking_reports_cubit.dart';
import '../state/company_booking_reports_state.dart';
import '../widgets/booking_report_list_tile.dart';

class CompanyBookingReportsPage extends StatefulWidget {
  const CompanyBookingReportsPage({super.key});

  @override
  State<CompanyBookingReportsPage> createState() =>
      _CompanyBookingReportsPageState();
}

class _CompanyBookingReportsPageState extends State<CompanyBookingReportsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyBookingReportsCubit>().load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final cubit = context.read<CompanyBookingReportsCubit>();
    final state = cubit.state;
    if (state is! CompanyBookingReportsLoaded ||
        state.isLoadingMore ||
        !state.hasNextPage) {
      return;
    }
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    cubit.loadNextPage();
  }

  Future<void> _refresh() =>
      context.read<CompanyBookingReportsCubit>().refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'بلاغات الحجوزات',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<CompanyBookingReportsCubit, CompanyBookingReportsState>(
        builder: (context, state) {
          if (state is CompanyBookingReportsLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: 6,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacing12),
                child: LoadingShimmerWidget(height: 120),
              ),
            );
          }

          if (state is CompanyBookingReportsError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<CompanyBookingReportsCubit>().load(),
            );
          }

          if (state is! CompanyBookingReportsLoaded) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppTheme.primaryTeal,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _StatusFilterChips(
                      selected: state.statusFilter,
                      openCount: state.openReportsCount,
                      onSelected: (status) =>
                          context.read<CompanyBookingReportsCubit>().setStatusFilter(status),
                    ),
                  ),
                ),
                if (state.reports.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.report_problem_outlined,
                              size: 56,
                              color: AppTheme.gray400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد بلاغات',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: state.reports.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spacing12),
                      itemBuilder: (context, index) {
                        if (index == state.reports.length) {
                          return PagedListFooter(
                            isLoadingMore: state.isLoadingMore,
                            hasNextPage: state.hasNextPage,
                          );
                        }
                        return BookingReportListTile(report: state.reports[index]);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.selected,
    required this.onSelected,
    this.openCount,
  });

  final int? selected;
  final int? openCount;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          _Chip(
            label: 'مرفوض',
            selected: selected == BookingReportStatus.rejected,
            onTap: () => onSelected(BookingReportStatus.rejected),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'تم الحل',
            selected: selected == BookingReportStatus.resolved,
            onTap: () => onSelected(BookingReportStatus.resolved),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'قيد المراجعة',
            selected: selected == BookingReportStatus.inReview,
            onTap: () => onSelected(BookingReportStatus.inReview),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: openCount != null && openCount! > 0
                ? 'مفتوح ($openCount)'
                : 'مفتوح',
            selected: selected == BookingReportStatus.open,
            onTap: () => onSelected(BookingReportStatus.open),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'الكل',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryTeal,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppTheme.primaryTeal : AppTheme.gray700,
      ),
    );
  }
}
