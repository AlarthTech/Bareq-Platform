import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../cubit/my_reports_cubit.dart';
import '../cubit/my_reports_state.dart';
import '../utils/report_navigation.dart';
import '../widgets/report_target_tile.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key, this.returnRoute});

  /// When set, back navigates here if the stack cannot pop (e.g. after report submit).
  final String? returnRoute;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyReportsCubit>()..loadFirstPage(),
      child: _MyReportsPageContent(returnRoute: returnRoute),
    );
  }
}

class _MyReportsPageContent extends StatefulWidget {
  const _MyReportsPageContent({this.returnRoute});

  final String? returnRoute;

  @override
  State<_MyReportsPageContent> createState() => _MyReportsPageContentState();
}

class _MyReportsPageContentState extends State<_MyReportsPageContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max - 200) {
      context.read<MyReportsCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('myReports') ?? 'My reports',
        showBackButton: true,
        onBackPressed:
            () => popOrGoToReturnRoute(
              context,
              returnRoute: widget.returnRoute,
            ),
      ),
      body: BlocBuilder<MyReportsCubit, MyReportsState>(
        builder: (context, state) {
          if (state is MyReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MyReportsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          () => context.read<MyReportsCubit>().loadFirstPage(),
                      child: Text(l10n?.translate('retry') ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MyReportsLoaded) {
            if (state.reports.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n?.translate('noReportsYet') ??
                        'You have not submitted any reports yet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<MyReportsCubit>().refresh(),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    state.reports.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= state.reports.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final report = state.reports[index];
                  return ReportTargetTile(
                    report: report,
                    onTap:
                        () => context.push(
                          AppStrings.reportDetailRoute(report.id),
                        ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
