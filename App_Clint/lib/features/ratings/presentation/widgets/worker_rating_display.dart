import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/rating_summary.dart';
import '../../domain/usecases/rating_usecases.dart';
import '../extensions/rating_formatters.dart';
import '../rating_refresh_notifier.dart';
import 'rating_summary_row.dart';

/// Loads worker summary from API/cache and displays stars + count.
class WorkerRatingDisplay extends StatefulWidget {
  const WorkerRatingDisplay({
    super.key,
    required this.workerId,
    this.starSize = 18,
    this.alignment = MainAxisAlignment.center,
    this.textStyle,
    this.compact = false,
  });

  final int workerId;
  final double starSize;
  final MainAxisAlignment alignment;
  final TextStyle? textStyle;
  final bool compact;

  @override
  State<WorkerRatingDisplay> createState() => WorkerRatingDisplayState();
}

class WorkerRatingDisplayState extends State<WorkerRatingDisplay> {
  WorkerRatingSummary? _summary;
  bool _loading = true;
  late final RatingRefreshNotifier _refreshNotifier;

  @override
  void initState() {
    super.initState();
    _refreshNotifier = sl<RatingRefreshNotifier>();
    _refreshNotifier.addListener(_onRefreshSignal);
    _load();
  }

  @override
  void dispose() {
    _refreshNotifier.removeListener(_onRefreshSignal);
    super.dispose();
  }

  void _onRefreshSignal() {
    if (_refreshNotifier.workerId == widget.workerId) {
      _load(force: true);
    }
  }

  @override
  void didUpdateWidget(covariant WorkerRatingDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workerId != widget.workerId) {
      _load();
    }
  }

  Future<void> reload() => _load(force: true);

  Future<void> _load({bool force = false}) async {
    if (force) {
      sl<InvalidateRatingCacheUseCase>().forWorker(widget.workerId);
    }
    if (!mounted) return;
    setState(() => _loading = true);

    final result = await sl<GetWorkerRatingSummaryUseCase>()(widget.workerId);
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        _summary = WorkerRatingSummary(
          workerId: widget.workerId,
          averageRating: 0,
          totalReviews: 0,
        );
        _loading = false;
      }),
      (summary) => setState(() {
        _summary = summary;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.starSize + 4,
        width: widget.alignment == MainAxisAlignment.center
            ? double.infinity
            : null,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final summary = _summary ??
        WorkerRatingSummary(
          workerId: widget.workerId,
          averageRating: 0,
          totalReviews: 0,
        );

    final ratingWidget = widget.compact && !summary.hasReviews
        ? Text(
            reviewCountLabel(0, context),
            style: widget.textStyle,
            textAlign: widget.alignment == MainAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
          )
        : RatingSummaryRow(
            summary: summary,
            starSize: widget.starSize,
            textStyle: widget.textStyle,
            alignment: widget.alignment,
          );

    if (widget.alignment == MainAxisAlignment.center) {
      return Center(child: ratingWidget);
    }

    return ratingWidget;
  }
}
