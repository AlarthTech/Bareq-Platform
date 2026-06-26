import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_empty_state.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../state/my_booking_reports_cubit.dart';
import '../state/my_booking_reports_state.dart';
import '../widgets/booking_report_list_tile.dart';

class MyBookingReportsPage extends StatelessWidget {
  const MyBookingReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyBookingReportsCubit>()..loadFirstPage(),
      child: const _MyBookingReportsPageContent(),
    );
  }
}

class _MyBookingReportsPageContent extends StatefulWidget {
  const _MyBookingReportsPageContent();

  @override
  State<_MyBookingReportsPageContent> createState() =>
      _MyBookingReportsPageContentState();
}

class _MyBookingReportsPageContentState
    extends State<_MyBookingReportsPageContent> {
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
      context.read<MyBookingReportsCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('myBookingReports') ?? 'بلاغات الحجوزات',
        showBackButton: true,
      ),
      body: BlocBuilder<MyBookingReportsCubit, MyBookingReportsState>(
        builder: (context, state) {
          if (state is MyBookingReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MyBookingReportsError) {
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
                          () =>
                              context.read<MyBookingReportsCubit>().loadFirstPage(),
                      child: Text(l10n?.translate('retry') ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MyBookingReportsLoaded) {
            if (state.reports.isEmpty) {
              return AppEmptyState(
                icon: Icons.report_problem_outlined,
                title:
                    l10n?.translate('noBookingReportsYet') ??
                    'No booking reports yet',
                subtitle:
                    l10n?.translate('noBookingReportsHint') ??
                    'You can submit a report from a booking details page.',
              );
            }

            return RefreshIndicator(
              onRefresh: context.read<MyBookingReportsCubit>().refresh,
              color: AppColors.primary,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    state.reports.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= state.reports.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final report = state.reports[index];
                  return BookingReportListTile(
                    report: report,
                    onTap:
                        () => context.push(
                          AppStrings.bookingReportDetailRoute(report.id),
                          extra: report,
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
