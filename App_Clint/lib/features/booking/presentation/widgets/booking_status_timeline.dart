import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum _StepVisualState { completed, current, upcoming }

/// Horizontal booking progress timeline (scrollable when many steps).
class BookingStatusTimeline extends StatelessWidget {
  const BookingStatusTimeline({
    super.key,
    required this.activeStepIndex,
    required this.stepLabels,
    this.inProgressStepIndex,
  });

  final int activeStepIndex;
  final List<String> stepLabels;

  /// When this step is current, use green “in progress” styling.
  final int? inProgressStepIndex;

  static const double _stepWidth = 72;
  static const double _connectorWidth = 20;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stepLabels.length; i++) ...[
            _TimelineStep(
              label: stepLabels[i],
              width: _stepWidth,
              state: i < activeStepIndex
                  ? _StepVisualState.completed
                  : i == activeStepIndex
                  ? _StepVisualState.current
                  : _StepVisualState.upcoming,
              useInProgressStyle:
                  inProgressStepIndex == i &&
                  i == activeStepIndex &&
                  inProgressStepIndex != null,
            ),
            if (i < stepLabels.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: _connectorWidth,
                  child: _TimelineConnector(filled: i < activeStepIndex),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.width,
    required this.state,
    required this.useInProgressStyle,
  });

  final String label;
  final double width;
  final _StepVisualState state;
  final bool useInProgressStyle;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _StepVisualState.current;
    final isCompleted = state == _StepVisualState.completed;

    final accent = useInProgressStyle ? AppColors.success : AppColors.primary;

    Color circleColor;
    Color borderColor;
    Widget icon;

    if (isCompleted) {
      circleColor = accent;
      borderColor = accent;
      icon = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isCurrent) {
      circleColor = accent.withValues(alpha: 0.12);
      borderColor = accent;
      icon = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
        ),
      );
    } else {
      circleColor = AppColors.surfaceVariant;
      borderColor = AppColors.border.withValues(alpha: 0.6);
      icon = const SizedBox(width: 10, height: 10);
    }

    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isCurrent
                      ? accent
                      : isCompleted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color:
            filled ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
