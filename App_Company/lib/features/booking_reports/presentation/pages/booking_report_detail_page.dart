import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/booking_report_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../bookings/domain/usecases/get_booking_by_id_usecase.dart';
import '../../../bookings/presentation/bloc/booking_bloc.dart';
import '../../../bookings/presentation/models/booking_detail_extra.dart';
import '../state/booking_report_detail_cubit.dart';
import '../state/booking_report_detail_state.dart';
import '../state/update_booking_report_status_cubit.dart';
import '../state/update_booking_report_status_state.dart';
import '../../domain/entities/booking_report.dart';
import '../widgets/booking_report_status_badge.dart';
import '../widgets/update_booking_report_status_sheet.dart';

class BookingReportDetailPage extends StatefulWidget {
  const BookingReportDetailPage({super.key, required this.reportId});

  final int reportId;

  @override
  State<BookingReportDetailPage> createState() =>
      _BookingReportDetailPageState();
}

class _BookingReportDetailPageState extends State<BookingReportDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<BookingReportDetailCubit>().load(widget.reportId);
  }

  Future<void> _openBooking(int bookingId) async {
    final result = await getIt<GetBookingByIdUseCase>()(bookingId);
    if (!mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (booking) {
        context.push(
          AppRoutes.bookingDetail(bookingId),
          extra: BookingDetailExtra(
            booking: booking,
            bookingBloc: getIt<BookingBloc>(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UpdateBookingReportStatusCubit,
            UpdateBookingReportStatusState>(
          listener: (context, state) {
            if (state is UpdateBookingReportStatusSuccess) {
              context.read<BookingReportDetailCubit>().applyReport(state.report);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث حالة البلاغ')),
              );
              context.read<UpdateBookingReportStatusCubit>().reset();
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.surfaceBackground,
        appBar: AppAppBar(
          title: 'تفاصيل البلاغ',
          showLogout: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<BookingReportDetailCubit, BookingReportDetailState>(
          builder: (context, state) {
            if (state is BookingReportDetailLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: LoadingShimmerWidget(height: 320),
              );
            }
            if (state is BookingReportDetailError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: () => context
                    .read<BookingReportDetailCubit>()
                    .load(widget.reportId),
              );
            }
            if (state is! BookingReportDetailLoaded) {
              return const SizedBox.shrink();
            }

            final report = state.report;
            final showActions = !BookingReportStatus.isTerminal(report.status);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _HeaderSection(report: report),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'الحجز',
                        children: [
                          _DetailRow(
                            label: 'رقم الحجز',
                            value: '#${report.bookingId}',
                            onTap: () => _openBooking(report.bookingId),
                            linkStyle: true,
                          ),
                          _DetailRow(
                            label: 'حالة الحجز',
                            value: report.bookingStatusName,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'الأطراف',
                        children: [
                          _DetailRow(
                            label: 'العميل',
                            value: report.customerName,
                          ),
                          if (report.workerName != null &&
                              report.workerName!.trim().isNotEmpty)
                            _DetailRow(
                              label: 'العاملة',
                              value: report.workerName!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'الشكوى',
                        children: [
                          _DetailRow(label: 'السبب', value: report.reason),
                          if (report.description != null &&
                              report.description!.trim().isNotEmpty)
                            _DetailRow(
                              label: 'التفاصيل',
                              value: report.description!.trim(),
                              multiline: true,
                            ),
                        ],
                      ),
                      if (report.isTerminal &&
                          (report.adminResolutionNotes?.trim().isNotEmpty ==
                              true)) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'الحل',
                          children: [
                            _DetailRow(
                              label: 'ملاحظات الحل',
                              value: report.adminResolutionNotes!.trim(),
                              multiline: true,
                            ),
                            if (report.resolvedByAdminName != null)
                              _DetailRow(
                                label: 'تم بواسطة',
                                value: report.resolvedByAdminName!,
                              ),
                            if (report.resolvedAt != null)
                              _DetailRow(
                                label: 'تاريخ الحل',
                                value: DateFormatter.formatDisplayWeekdayDate(
                                  report.resolvedAt!,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (showActions)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: FilledButton.icon(
                        onPressed: () => UpdateBookingReportStatusSheet.show(
                          context,
                          reportId: report.id,
                          currentStatus: report.status,
                        ),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('تحديث الحالة'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.report});

  final BookingReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              BookingReportStatusBadge(
                status: report.status,
                statusName: report.statusName,
              ),
              const Spacer(),
              Text(
                '#${report.id}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormatter.formatDisplayWeekdayDate(report.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gray900,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
    this.onTap,
    this.linkStyle = false,
  });

  final String label;
  final String value;
  final bool multiline;
  final VoidCallback? onTap;
  final bool linkStyle;

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: linkStyle ? AppTheme.primaryTeal : AppTheme.gray900,
            fontWeight: linkStyle ? FontWeight.w700 : FontWeight.w600,
            height: multiline ? 1.45 : null,
            decoration: linkStyle ? TextDecoration.underline : null,
          ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.gray500,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          if (onTap != null)
            InkWell(onTap: onTap, child: valueWidget)
          else
            valueWidget,
        ],
      ),
    );
  }
}
