import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../state/company_booking_reports_cubit.dart';
import '../state/company_booking_reports_state.dart';
import '../widgets/booking_report_list_tile.dart';

/// Section on booking detail showing reports filed against this booking.
class BookingReportsForBookingSection extends StatelessWidget {
  const BookingReportsForBookingSection({
    super.key,
    required this.bookingId,
  });

  final int bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CompanyBookingReportsCubit>()
        ..load(bookingId: bookingId),
      child: _BookingReportsForBookingBody(bookingId: bookingId),
    );
  }
}

class _BookingReportsForBookingBody extends StatelessWidget {
  const _BookingReportsForBookingBody({required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyBookingReportsCubit, CompanyBookingReportsState>(
      builder: (context, state) {
        if (state is CompanyBookingReportsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (state is CompanyBookingReportsError) {
          return Text(
            state.message,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.dangerRed,
                ),
          );
        }

        if (state is! CompanyBookingReportsLoaded) {
          return const SizedBox.shrink();
        }

        if (state.reports.isEmpty) {
          return Text(
            'لا توجد بلاغات على هذا الحجز',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray600,
                ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final report in state.reports) ...[
              BookingReportListTile(
                report: report,
                onTap: () => context.push(
                  AppRoutes.companyBookingReportDetail(report.id),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
