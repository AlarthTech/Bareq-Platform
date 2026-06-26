import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/booking_report_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../state/update_booking_report_status_cubit.dart';
import '../state/update_booking_report_status_state.dart';

class UpdateBookingReportStatusSheet extends StatefulWidget {
  const UpdateBookingReportStatusSheet({
    super.key,
    required this.reportId,
    required this.currentStatus,
  });

  final int reportId;
  final int currentStatus;

  static Future<void> show(
    BuildContext context, {
    required int reportId,
    required int currentStatus,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<UpdateBookingReportStatusCubit>(),
        child: UpdateBookingReportStatusSheet(
          reportId: reportId,
          currentStatus: currentStatus,
        ),
      ),
    );
  }

  @override
  State<UpdateBookingReportStatusSheet> createState() =>
      _UpdateBookingReportStatusSheetState();
}

class _UpdateBookingReportStatusSheetState
    extends State<UpdateBookingReportStatusSheet> {
  int? _selectedStatus;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _notesRequired =>
      _selectedStatus != null &&
      BookingReportStatus.requiresNotes(_selectedStatus!);

  void _submit() {
    final status = _selectedStatus;
    if (status == null) return;

    context.read<UpdateBookingReportStatusCubit>().submit(
          reportId: widget.reportId,
          status: status,
          adminResolutionNotes: _notesController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<UpdateBookingReportStatusCubit,
        UpdateBookingReportStatusState>(
      listener: (context, state) {
        if (state is UpdateBookingReportStatusSuccess) {
          Navigator.of(context).pop();
        } else if (state is UpdateBookingReportStatusError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تحديث الحالة',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            if (widget.currentStatus == BookingReportStatus.open)
              _ActionTile(
                title: 'بدء المراجعة',
                subtitle: 'نقل البلاغ إلى قيد المراجعة',
                icon: Icons.rate_review_outlined,
                color: AppTheme.infoBlue,
                selected: _selectedStatus == BookingReportStatus.inReview,
                onTap: () => setState(
                  () => _selectedStatus = BookingReportStatus.inReview,
                ),
              ),
            if (widget.currentStatus != BookingReportStatus.resolved)
              _ActionTile(
                title: 'تم الحل',
                subtitle: 'ملاحظات الحل مطلوبة',
                icon: Icons.check_circle_outline,
                color: AppTheme.successGreen,
                selected: _selectedStatus == BookingReportStatus.resolved,
                onTap: () => setState(
                  () => _selectedStatus = BookingReportStatus.resolved,
                ),
              ),
            if (widget.currentStatus != BookingReportStatus.rejected)
              _ActionTile(
                title: 'رفض البلاغ',
                subtitle: 'ملاحظات الرفض مطلوبة',
                icon: Icons.block_outlined,
                color: AppTheme.dangerRed,
                selected: _selectedStatus == BookingReportStatus.rejected,
                onTap: () => setState(
                  () => _selectedStatus = BookingReportStatus.rejected,
                ),
              ),
            if (_selectedStatus != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLength: 1000,
                minLines: 3,
                maxLines: 5,
                textAlign: TextAlign.right,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'ملاحظات الحل',
                  hintText: _notesRequired
                      ? 'مطلوب عند الحل أو الرفض'
                      : 'اختياري',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  counterText:
                      '${_notesController.text.characters.length}/1000',
                ),
              ),
            ],
            const SizedBox(height: 16),
            BlocBuilder<UpdateBookingReportStatusCubit,
                UpdateBookingReportStatusState>(
              builder: (context, state) {
                final loading = state is UpdateBookingReportStatusLoading;
                return FilledButton(
                  onPressed: _selectedStatus == null || loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حفظ'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? color.withValues(alpha: 0.08) : AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : AppTheme.gray200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.gray600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
