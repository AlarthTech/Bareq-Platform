import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/failure_ui.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../auth/domain/usecases/clear_user_usecase.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/usecases/get_my_booking_reports_usecase.dart';
import '../widgets/booking_report_status_badge.dart';

class BookingReportDetailPage extends StatefulWidget {
  const BookingReportDetailPage({
    super.key,
    required this.reportId,
    this.initialReport,
  });

  final int reportId;
  final BookingReport? initialReport;

  @override
  State<BookingReportDetailPage> createState() =>
      _BookingReportDetailPageState();
}

class _BookingReportDetailPageState extends State<BookingReportDetailPage> {
  BookingReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null &&
        widget.initialReport!.id == widget.reportId) {
      _report = widget.initialReport;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    var page = 1;
    BookingReport? found;
    String? loadError;

    while (found == null) {
      final result = await sl<GetMyBookingReportsUseCase>()(page: page);
      if (!mounted) return;

      final shouldContinue = await result.fold<Future<bool>>(
        (failure) async {
          if (failureRequiresLogout(failure)) {
            await sl<ClearUserUseCase>().call();
            if (mounted) context.go(AppStrings.routeLogin);
            return false;
          }
          loadError = failureMessage(context, failure);
          return false;
        },
        (pageResult) async {
          for (final report in pageResult.items) {
            if (report.id == widget.reportId) {
              found = report;
              break;
            }
          }
          if (found != null || !pageResult.hasNextPage) return false;
          page = pageResult.page + 1;
          return true;
        },
      );

      if (!shouldContinue) break;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _report = found;
      _error = found == null ? (loadError ?? 'bookingReportNotFound') : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('bookingReportDetail') ?? 'تفاصيل البلاغ',
        showBackButton: true,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.translate(_error!) ?? _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: Text(l10n?.translate('retry') ?? 'Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : _report == null
              ? const SizedBox.shrink()
              : _buildContent(context, _report!),
    );
  }

  Widget _buildContent(BuildContext context, BookingReport report) {
    final l10n = L10n.of(context);
    final createdAt = DateFormat.yMMMd().add_Hm().format(
      report.createdAt.toLocal(),
    );
    final resolvedAt =
        report.resolvedAt == null
            ? null
            : DateFormat.yMMMd().add_Hm().format(report.resolvedAt!.toLocal());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${report.bookingId}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              BookingReportStatusBadge(
                statusName: report.statusName,
                status: report.statusEnum,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.bookingStatusName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          _InfoSection(
            title: l10n?.translate('company') ?? 'Company',
            value: report.companyName,
          ),
          if (report.workerName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _InfoSection(
              title: l10n?.translate('worker') ?? 'Worker',
              value: report.workerName!,
            ),
          ],
          const SizedBox(height: 20),
          _InfoSection(
            title: l10n?.translate('bookingReportReason') ?? 'سبب البلاغ',
            value: report.reason,
          ),
          if (report.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _InfoSection(
              title:
                  l10n?.translate('bookingReportDescription') ??
                  'تفاصيل إضافية',
              value: report.description!,
            ),
          ],
          const SizedBox(height: 20),
          _InfoSection(
            title: l10n?.translate('createdAt') ?? 'Created',
            value: createdAt,
          ),
          if (report.showAdminNotes) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.translate('adminResolutionNotes') ??
                        'ملاحظات الإدارة',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.adminResolutionNotes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                  if (resolvedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      resolvedAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n?.translate('resolvedByAdministration') ??
                        'تم الحل بواسطة الإدارة',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}
