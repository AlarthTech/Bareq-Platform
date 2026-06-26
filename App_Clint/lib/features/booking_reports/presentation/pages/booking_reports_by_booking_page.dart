import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_empty_state.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../state/booking_reports_by_booking_cubit.dart';
import '../state/booking_reports_by_booking_state.dart';
import '../widgets/booking_report_list_tile.dart';

class BookingReportsByBookingPage extends StatelessWidget {
  const BookingReportsByBookingPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              sl<BookingReportsByBookingCubit>(param1: bookingId)..loadFirstPage(),
      child: _BookingReportsByBookingPageContent(bookingId: bookingId),
    );
  }
}

class _BookingReportsByBookingPageContent extends StatefulWidget {
  const _BookingReportsByBookingPageContent({required this.bookingId});

  final int bookingId;

  @override
  State<_BookingReportsByBookingPageContent> createState() =>
      _BookingReportsByBookingPageContentState();
}

class _BookingReportsByBookingPageContentState
    extends State<_BookingReportsByBookingPageContent> {
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
      context.read<BookingReportsByBookingCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title:
            l10n?.translate('bookingReportsForBooking') ??
            'بلاغات هذا الحجز',
        showBackButton: true,
      ),
      body: BlocBuilder<BookingReportsByBookingCubit,
          BookingReportsByBookingState>(
        builder: (context, state) {
          if (state is BookingReportsByBookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BookingReportsByBookingError) {
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
                          () => context
                              .read<BookingReportsByBookingCubit>()
                              .loadFirstPage(),
                      child: Text(l10n?.translate('retry') ?? 'Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is BookingReportsByBookingLoaded) {
            if (state.reports.isEmpty) {
              return AppEmptyState(
                icon: Icons.report_problem_outlined,
                title:
                    l10n?.translate('noBookingReportsForThisBooking') ??
                    'No reports for this booking',
              );
            }

            return RefreshIndicator(
              onRefresh: context.read<BookingReportsByBookingCubit>().refresh,
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
