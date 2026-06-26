import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_entity.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_detail_cubit.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../cubit/booking_realtime_cubit.dart';
import '../widgets/booking_location_section.dart';
import '../widgets/booking_status_display.dart';
import '../../../booking_reports/presentation/widgets/booking_reports_for_booking_section.dart';

/// Full-screen booking details: summary, sections, timeline, status actions.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BookingDetailCubit>().refreshFromApi();
  }

  void _syncFromBloc(BookingsLoaded state, int bookingId) {
    for (final b in state.bookings) {
      if (b.id == bookingId) {
        context.read<BookingDetailCubit>().applyBooking(b);
        return;
      }
    }
  }

  void _updateStatus(BookingEntity booking, int status, {String? rejectionReason}) {
    context.read<BookingBloc>().add(
          UpdateBookingStatusEvent(
            bookingId: booking.id,
            statusValue: status,
            rejectionReason: rejectionReason,
          ),
        );
  }

  void _showRejectDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض الحجز'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (مطلوب)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال سبب الرفض')),
                );
                return;
              }
              Navigator.pop(ctx);
              _updateStatus(
                context.read<BookingDetailCubit>().state.booking,
                AppConstants.statusRejected,
                rejectionReason: reason,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('رفض'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text('سيتم إلغاء هذا الحجز ولن يُحتسب كمكتمل. المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(
                context.read<BookingDetailCubit>().state.booking,
                AppConstants.statusCanceled,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.gray700),
            child: const Text('إلغاء الحجز'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingDetailCubit, BookingDetailState>(
      builder: (context, detailState) {
        final _booking = detailState.booking;
        final isRejected = _booking.status == AppConstants.statusRejected;
        final isCanceled = _booking.status == AppConstants.statusCanceled;
        final visual = bookingDisplayVisual(_booking);

        return BlocListener<BookingRealtimeCubit, BookingRealtimeState>(
          listenWhen: (prev, curr) =>
              curr.lastEvent != null &&
              curr.lastEvent!.bookingId == _booking.id &&
              prev.lastEvent != curr.lastEvent,
          listener: (context, rtState) {
            final event = rtState.lastEvent;
            if (event == null) return;
            context.read<BookingDetailCubit>().applyStatusChange(event.status);
            context.read<BookingBloc>().add(
                  BookingStatusChangedRealtimeEvent(
                    bookingId: event.bookingId,
                    status: event.status,
                  ),
                );
          },
          child: BlocListener<BookingBloc, BookingState>(
      listenWhen: (p, c) => c is BookingError || c is BookingsLoaded,
      listener: (context, state) {
        if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.dangerRed),
          );
        } else if (state is BookingsLoaded) {
          _syncFromBloc(state, _booking.id);
        }
      },
      child: BlocListener<BookingDetailCubit, BookingDetailState>(
        listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
        listener: (context, state) {
          final msg = state.errorMessage;
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: AppTheme.dangerRed),
            );
          }
        },
        child: Scaffold(
        backgroundColor: isRejected
            ? const Color(0xFFFCF5F5)
            : isCanceled
                ? const Color(0xFFF8F9FB)
                : AppTheme.gray50,
        appBar: AppBar(
          title: const Text('تفاصيل الحجز'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: KeyedSubtree(
                key: ValueKey<String>(
                  '${_booking.status}_${_booking.isWorkerArrivalConfirmed}',
                ),
                child: _SummaryCard(
                  booking: _booking,
                  visual: visual,
                  highlightRejected: isRejected,
                  highlightCanceled: isCanceled,
                ),
              ),
            ),
            if (bookingShowsOnTheWayArrivalUi(_booking)) ...[
              const SizedBox(height: 16),
              BookingOnTheWayInfoCard(booking: _booking),
            ],
            const SizedBox(height: 24),
            _SectionTitle(title: 'معلومات الحجز'),
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                _LabelValueBlock(
                  label: 'العميل',
                  value: _booking.customerDisplayName,
                ),
                const SizedBox(height: 18),
                _LabelValueBlock(
                  label: 'الشركة',
                  value: _nonEmpty(_booking.companyName) ?? 'لم يُحدد',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'موقع الخدمة'),
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                if (_booking.displayAddress == null && !_booking.hasMapCoordinates)
                  Text(
                    'لم يُحدد موقع',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.gray600,
                        ),
                  )
                else
                  BookingLocationSection(booking: _booking),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'الوقت والتاريخ'),
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                _LabelValueBlock(
                  label: 'التاريخ',
                  value: _formatDateReadable(_booking.bookingDate),
                ),
                const SizedBox(height: 18),
                _LabelValueBlock(
                  label: 'الوقت',
                  value: _formatTimeRange(_booking),
                ),
                if (_durationLine(_booking) != null) ...[
                  const SizedBox(height: 18),
                  _LabelValueBlock(
                    label: 'المدة',
                    value: _durationLine(_booking)!,
                  ),
                ],
                if (bookingIsCleaningInProgress(_booking)) ...[
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),
                  BookingArrivalConfirmationSection(booking: _booking),
                ],
              ],
            ),
            if (_nonEmpty(_booking.notes) != null) ...[
              const SizedBox(height: 24),
              _SectionTitle(title: 'ملاحظات'),
              const SizedBox(height: 12),
              _DetailCard(
                children: [
                  Text(
                    _booking.notes!.trim(),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.gray800,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ],
            if (_booking.status == AppConstants.statusRejected &&
                _nonEmpty(_booking.rejectionReason) != null) ...[
              const SizedBox(height: 24),
              _SectionTitle(title: 'سبب الرفض'),
              const SizedBox(height: 12),
              _DetailCard(
                children: [
                  Text(
                    _booking.rejectionReason!.trim(),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.dangerRed,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            _SectionTitle(title: 'بلاغات الحجز'),
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                BookingReportsForBookingSection(bookingId: _booking.id),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(title: 'سجل الحجز'),
            const SizedBox(height: 12),
            _BookingTimeline(booking: _booking),
            const SizedBox(height: 100),
          ],
        ),
        bottomNavigationBar: _CompanyBookingActionBar(
          booking: _booking,
          onApprove: () => _updateStatus(_booking, AppConstants.statusApproved),
          onReject: _showRejectDialog,
          onCancel: _showCancelDialog,
          onMarkOnTheWay: () => _updateStatus(_booking, AppConstants.statusOnTheWay),
          onComplete: () => _updateStatus(_booking, AppConstants.statusCompleted),
        ),
        ),
      ),
    ),
    );
      },
    );
  }
}

// --- Summary ---

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.booking,
    required this.visual,
    required this.highlightRejected,
    required this.highlightCanceled,
  });

  final BookingEntity booking;
  final BookingStatusVisual visual;
  final bool highlightRejected;
  final bool highlightCanceled;

  @override
  Widget build(BuildContext context) {
    final service = booking.workTypeName?.trim().isNotEmpty == true ? booking.workTypeName!.trim() : '—';
    final maid =
        (booking.workerName != null && booking.workerName!.trim().isNotEmpty) ? booking.workerName!.trim() : '—';

    final Color bg;
    final Color borderColor;
    if (highlightRejected) {
      bg = const Color(0xFFFFF8F8);
      borderColor = AppTheme.dangerRed.withValues(alpha: 0.12);
    } else if (highlightCanceled) {
      bg = const Color(0xFFF5F6F8);
      borderColor = AppTheme.gray300;
    } else {
      bg = Colors.white;
      borderColor = AppTheme.gray200;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: ui.TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  booking.customerDisplayName,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.25,
                        color: AppTheme.gray900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$service • $maid',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray700,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 10),
                _SummaryDateTimeLine(booking: booking),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BookingStatusPill(visual: visual),
        ],
      ),
    );
  }
}

class _SummaryDateTimeLine extends StatelessWidget {
  const _SummaryDateTimeLine({required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.gray800,
          fontWeight: FontWeight.w600,
        );
    final datePart = _fmtDateCompact(booking.bookingDate);
    final timePart = _formatTimeRange(booking);
    if (booking.bookingDate == null) {
      return Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Text(
          timePart,
          textAlign: TextAlign.right,
          style: baseStyle?.copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: datePart),
          const TextSpan(text: ' • '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                timePart,
                style: baseStyle?.copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.right,
    );
  }
}

// --- Sections ---

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.gray600,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LabelValueBlock extends StatelessWidget {
  const _LabelValueBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.gray500,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.gray900,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

// --- Timeline ---

class _BookingTimeline extends StatelessWidget {
  const _BookingTimeline({required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final steps = _timelineSteps(booking);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _TimelineRow(
              step: steps[i],
              isLast: i == steps.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.done,
    this.isCurrent = false,
    this.subtitle,
  });

  final String title;
  final bool done;
  final bool isCurrent;
  final String? subtitle;
}

/// API workflow: 0 → 1 → (2) → 3, or branches 4 / 5 from pending; 3 may be set automatically after end time.
List<_TimelineStep> _timelineSteps(BookingEntity b) {
  final s = b.status;
  final out = <_TimelineStep>[];

  out.add(
    _TimelineStep(
      title: 'قيد الانتظار',
      done: s != AppConstants.statusPending,
      isCurrent: s == AppConstants.statusPending,
    ),
  );

  if (s == AppConstants.statusCanceled) {
    out.add(
      const _TimelineStep(
        title: 'أُلغي الحجز',
        done: true,
      ),
    );
    return out;
  }

  if (s == AppConstants.statusRejected) {
    out.add(
      _TimelineStep(
        title: 'مرفوض',
        done: true,
        subtitle: _nonEmpty(b.rejectionReason),
      ),
    );
    return out;
  }

  out.add(
    _TimelineStep(
      title: 'مقبول',
      done: s >= AppConstants.statusApproved,
      isCurrent: s == AppConstants.statusApproved,
    ),
  );
  final onTheWayTitle = b.isWorkerArrivalConfirmed &&
          (s == AppConstants.statusOnTheWay || s >= AppConstants.statusCompleted)
      ? AppConstants.statusCleaningStartedText
      : AppConstants.statusOnTheWayText;
  out.add(
    _TimelineStep(
      title: onTheWayTitle,
      done: s >= AppConstants.statusOnTheWay,
      isCurrent: s == AppConstants.statusOnTheWay,
    ),
  );
  out.add(
    _TimelineStep(
      title: 'مكتمل',
      done: s >= AppConstants.statusCompleted,
      isCurrent: s == AppConstants.statusCompleted,
    ),
  );
  return out;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.done ? AppTheme.primaryTeal : AppTheme.gray300;
    final textColor = step.done ? AppTheme.gray900 : AppTheme.gray400;
    final titleWeight = step.isCurrent ? FontWeight.w800 : FontWeight.w700;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: ui.TextDirection.rtl,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.done ? AppTheme.primaryTeal : AppTheme.gray200,
                border: Border.all(
                  color: step.done ? AppTheme.primaryTeal : AppTheme.gray300,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: color.withValues(alpha: 0.35),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  step.title,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: titleWeight,
                        color: textColor,
                      ),
                ),
                if (step.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle!,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.gray500),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Bottom actions (company: API workflow 0→1→2→3, branches 4/5 from 0) ---

class _CompanyBookingActionBar extends StatelessWidget {
  const _CompanyBookingActionBar({
    required this.booking,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onMarkOnTheWay,
    required this.onComplete,
  });

  final BookingEntity booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onMarkOnTheWay;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final s = booking.status;
    if (AppConstants.isBookingTerminal(s)) {
      return const SizedBox.shrink();
    }

    if (s == AppConstants.statusPending) {
      return _actionBarShell(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onApprove,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('قبول الحجز'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRed,
                  side: BorderSide(color: AppTheme.dangerRed.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('رفض (سبب مطلوب)'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.gray700,
                  side: const BorderSide(color: AppTheme.gray300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إلغاء الحجز'),
              ),
            ),
          ],
        ),
      );
    }

    if (s == AppConstants.statusApproved) {
      return _actionBarShell(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onMarkOnTheWay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('العاملة في الطريق'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onComplete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  side: BorderSide(color: AppTheme.primaryTeal.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إكمال مباشرة'),
              ),
            ),
          ],
        ),
      );
    }

    if (s == AppConstants.statusOnTheWay) {
      return _actionBarShell(
        context,
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onComplete,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إكمال وإغلاق الحجز'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionBarShell(BuildContext context, Widget child) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: child,
        ),
      ),
    );
  }
}

// --- Formatting ---

String? _nonEmpty(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

String _formatDateReadable(DateTime? d) {
  if (d == null) return 'لم يُحدد';
  return DateFormatter.formatDisplayWeekdayDate(d);
}

String _fmtDateCompact(DateTime? d) {
  if (d == null) return '—';
  return DateFormatter.formatDisplayWeekdayCompact(d);
}

String _formatTimeRange(BookingEntity b) {
  final s = b.startTime;
  final e = b.endTime;
  if ((s == null || s.trim().isEmpty) && (e == null || e.trim().isEmpty)) {
    return 'لم يتم تحديد الوقت';
  }
  if (s != null && e != null && s.trim().isNotEmpty && e.trim().isNotEmpty) {
    return '${s.trim()} → ${e.trim()}';
  }
  return (s ?? e ?? '').trim().isEmpty ? 'لم يتم تحديد الوقت' : (s ?? e)!.trim();
}

String? _durationLine(BookingEntity b) {
  final sm = _parseMinutes(b.startTime);
  final em = _parseMinutes(b.endTime);
  if (sm == null || em == null) return null;
  var diff = em - sm;
  if (diff < 0) diff += 24 * 60;
  if (diff <= 0) return null;
  final h = diff ~/ 60;
  final m = diff % 60;
  if (h > 0 && m > 0) return '$h ساعة و $m دقيقة';
  if (h > 0) return '$h ساعة';
  return '$m دقيقة';
}

int? _parseMinutes(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  final parts = t.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0].trim()) ?? 0;
  final m = int.tryParse(parts[1].trim().split(RegExp(r'\s'))[0]) ?? 0;
  return h * 60 + m;
}

/// Shown when opening detail without valid [BookingDetailExtra] (e.g. deep link).
class BookingDetailMissingScreen extends StatelessWidget {
  const BookingDetailMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الحجز'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'تعذر فتح تفاصيل هذا الحجز. ارجع إلى القائمة وافتح الحجز من هناك.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.gray600, height: 1.5),
          ),
        ),
      ),
    );
  }
}
