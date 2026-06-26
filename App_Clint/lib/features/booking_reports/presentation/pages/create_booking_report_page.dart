import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../booking/domain/entities/booking_status_codes.dart';
import '../models/create_booking_report_args.dart';
import '../state/create_booking_report_cubit.dart';
import '../state/create_booking_report_state.dart';
import '../utils/booking_report_policy.dart';

class CreateBookingReportPage extends StatelessWidget {
  const CreateBookingReportPage({super.key, required this.args});

  final CreateBookingReportArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreateBookingReportCubit>(param1: args),
      child: _CreateBookingReportPageContent(args: args),
    );
  }
}

class _CreateBookingReportPageContent extends StatefulWidget {
  const _CreateBookingReportPageContent({required this.args});

  final CreateBookingReportArgs args;

  @override
  State<_CreateBookingReportPageContent> createState() =>
      _CreateBookingReportPageContentState();
}

class _CreateBookingReportPageContentState
    extends State<_CreateBookingReportPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _translateKey(String? key) {
    if (key == null) return null;
    final l10n = L10n.of(context);
    return l10n?.translate(key) ?? key;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final status = widget.args.bookingStatus;
    if (status == BookingStatusCodes.completed ||
        status == BookingStatusCodes.canceled) {
      final l10n = L10n.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('bookingReportNotAllowedStatus') ??
                'Cannot report completed or canceled bookings.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.read<CreateBookingReportCubit>().submit(
          reason: _reasonController.text,
          description: _descriptionController.text,
        );
  }

  Future<void> _onSuccess(CreateBookingReportSuccess state) async {
    final l10n = L10n.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.translate('bookingReportSubmittedMessage') ??
              'تم إرسال بلاغك بنجاح. سيتم مراجعته من قبل الإدارة.',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    final goToReports = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              l10n?.translate('bookingReportSubmittedTitle') ??
                  'تم إرسال البلاغ',
            ),
            content: Text(
              l10n?.translate('bookingReportSubmittedMessage') ??
                  'تم إرسال بلاغك بنجاح. سيتم مراجعته من قبل الإدارة.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n?.translate('close') ?? 'Close'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n?.translate('myBookingReports') ?? 'بلاغات الحجوزات',
                ),
              ),
            ],
          ),
    );
    if (!mounted) return;

    if (goToReports == true) {
      if (context.canPop()) context.pop(true);
      if (!mounted) return;
      context.push(AppStrings.routeMyBookingReports);
    } else {
      if (context.canPop()) {
        context.pop(true);
      } else if (widget.args.returnRoute != null) {
        context.go(widget.args.returnRoute!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final maxReason = BookingReportPolicy.maxReasonLength;
    final maxDescription = BookingReportPolicy.maxDescriptionLength;

    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('submitBookingReport') ?? 'تقديم بلاغ',
        showBackButton: true,
      ),
      body: BlocConsumer<CreateBookingReportCubit, CreateBookingReportState>(
        listener: (context, state) {
          if (state is CreateBookingReportSuccess) {
            _onSuccess(state);
          } else if (state is CreateBookingReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is CreateBookingReportLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n?.translate('booking') ?? 'Booking',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      widget.args.bookingLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _reasonController,
                    maxLength: maxReason,
                    enabled: !loading,
                    decoration: InputDecoration(
                      labelText:
                          l10n?.translate('bookingReportReason') ??
                          'سبب البلاغ',
                      counterText:
                          '${_reasonController.text.length}/$maxReason',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) => _translateKey(
                      BookingReportPolicy.validateReason(value ?? ''),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: maxDescription,
                    enabled: !loading,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText:
                          l10n?.translate('bookingReportDescription') ??
                          'تفاصيل إضافية',
                      alignLabelWithHint: true,
                      counterText:
                          '${_descriptionController.text.length}/$maxDescription',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) => _translateKey(
                      BookingReportPolicy.validateDescription(value),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        loading
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              l10n?.translate('submitBookingReportButton') ??
                                  'إرسال البلاغ',
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
