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
import '../../domain/entities/report.dart';
import '../../domain/usecases/delete_report_usecase.dart';
import '../../domain/usecases/get_report_by_id_usecase.dart';
import '../utils/report_navigation.dart';
import '../widgets/report_status_badge.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key, required this.reportId});

  final int reportId;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  Report? _report;
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<GetReportByIdUseCase>()(widget.reportId);
    if (!mounted) return;
    result.fold(
      (failure) {
        if (failureRequiresLogout(failure)) {
          sl<ClearUserUseCase>().call().then((_) {
            if (mounted) context.go(AppStrings.routeLogin);
          });
          return;
        }
        setState(() {
          _loading = false;
          _error = failureMessage(context, failure);
        });
      },
      (report) {
        setState(() {
          _loading = false;
          _report = report;
        });
      },
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n?.translate('deleteReport') ?? 'Delete report'),
            content: Text(
              l10n?.translate('deleteReportConfirm') ??
                  'Are you sure you want to delete this report?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n?.translate('cancel') ?? 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: Text(l10n?.translate('delete') ?? 'Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final result = await sl<DeleteReportUseCase>()(widget.reportId);
    if (!mounted) return;
    setState(() => _deleting = false);

    result.fold(
      (failure) {
        if (failureRequiresLogout(failure)) {
          sl<ClearUserUseCase>().call().then((_) {
            if (mounted) context.go(AppStrings.routeLogin);
          });
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage(context, failure)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.translate('reportDeleted') ?? 'Report deleted',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('reportDetail') ?? 'Report detail',
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          final report = _report;
          if (report != null) {
            final route = returnRouteForReport(report);
            if (route != null) {
              context.go(route);
              return;
            }
          }
          context.go(AppStrings.routeHome);
        },
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
              : _report == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _report!.targetDisplayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        ReportStatusBadge(
                          statusName: _report!.statusName,
                          status: _report!.status,
                        ),
                      ],
                    ),
                    if (_report!.targetTypeName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _report!.targetTypeName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n?.translate('reportDescriptionLabel') ??
                          'Report description',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _report!.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.translate('createdAt') ?? 'Created',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_Hm().format(
                        _report!.createdAt.toLocal(),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: _deleting ? null : _confirmDelete,
                      icon:
                          _deleting
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Icon(Icons.delete_outline),
                      label: Text(l10n?.translate('deleteReport') ?? 'Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
