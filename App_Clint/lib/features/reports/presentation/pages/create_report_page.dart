import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/entities/report.dart';
import '../cubit/create_report_cubit.dart';
import '../cubit/create_report_state.dart';
import '../models/create_report_args.dart';
import '../utils/report_description_validator.dart';
import '../utils/report_navigation.dart';

class CreateReportPage extends StatelessWidget {
  const CreateReportPage({super.key, required this.args});

  final CreateReportArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => sl<CreateReportCubit>(param1: args),
      child: _CreateReportPageContent(args: args),
    );
  }
}

class _CreateReportPageContent extends StatefulWidget {
  const _CreateReportPageContent({required this.args});

  final CreateReportArgs args;

  @override
  State<_CreateReportPageContent> createState() =>
      _CreateReportPageContentState();
}

class _CreateReportPageContentState extends State<_CreateReportPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String get _pageTitle {
    final l10n = L10n.of(context);
    return widget.args.targetType == ReportTargetType.worker
        ? (l10n?.translate('reportWorker') ?? 'Report worker')
        : (l10n?.translate('reportCompany') ?? 'Report company');
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CreateReportCubit>().submit(_descriptionController.text);
  }

  Future<void> _showSuccessActions() async {
    final l10n = L10n.of(context);
    final goToReports = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n?.translate('reportSubmittedTitle') ?? 'Report sent'),
            content: Text(
              l10n?.translate('reportSubmittedMessage') ??
                  'Your report was submitted and will be reviewed by administration.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n?.translate('close') ?? 'Close'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n?.translate('myReports') ?? 'My reports'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    final returnRoute =
        widget.args.returnRoute ??
        returnRouteForReportTarget(
          targetType: widget.args.targetType,
          targetId: widget.args.targetId,
        );
    if (goToReports == true) {
      if (context.canPop()) {
        context.pop();
      }
      if (!mounted) return;
      context.push(
        AppStrings.routeMyReports,
        extra: returnRoute,
      );
    } else {
      popOrGoToReturnRoute(context, returnRoute: returnRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final maxLen = ReportDescriptionValidator.maxLength;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        centerTitle: true,
      ),
      body: BlocConsumer<CreateReportCubit, CreateReportState>(
        listener: (context, state) {
          if (state is CreateReportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.translate('reportSubmittedMessage') ??
                      'Your report was submitted successfully.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            _showSuccessActions();
          } else if (state is CreateReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is CreateReportLoading;
          final length = _descriptionController.text.length;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n?.translate('reportAboutLabel') ?? 'Reporting about',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        widget.args.targetName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isLoading,
                      maxLines: 6,
                      maxLength: maxLen,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText:
                            l10n?.translate('reportDescriptionLabel') ??
                                'Report description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '$length/$maxLen',
                      ),
                      validator:
                          (v) => ReportDescriptionValidator.validate(
                            v,
                            requiredMessage:
                                l10n?.translate('reportDescriptionRequired'),
                            tooShortMessage:
                                l10n?.translate('reportDescriptionTooShort'),
                            tooLongMessage:
                                l10n?.translate('reportDescriptionTooLong'),
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                l10n?.translate('submitReport') ??
                                    'Submit report',
                              ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
