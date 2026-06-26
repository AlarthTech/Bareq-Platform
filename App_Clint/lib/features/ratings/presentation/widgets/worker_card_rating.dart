import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/rating_summary.dart';
import '../../domain/usecases/rating_usecases.dart';
import '../rating_refresh_notifier.dart';
import 'rating_badge.dart';

/// Compact worker rating for list/grid cards — loads Summary API per worker.
class WorkerCardRating extends StatefulWidget {
  const WorkerCardRating({
    super.key,
    required this.workerId,
    this.dense = false,
  });

  final int workerId;
  final bool dense;

  @override
  State<WorkerCardRating> createState() => _WorkerCardRatingState();
}

class _WorkerCardRatingState extends State<WorkerCardRating> {
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

  @override
  void didUpdateWidget(covariant WorkerCardRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workerId != widget.workerId) {
      _load();
    }
  }

  void _onRefreshSignal() {
    if (_refreshNotifier.workerId == widget.workerId) {
      _load(force: true);
    }
  }

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
      return SizedBox(height: widget.dense ? 12 : 16);
    }

    return RatingBadge(
      summary: _summary ??
          WorkerRatingSummary(
            workerId: widget.workerId,
            averageRating: 0,
            totalReviews: 0,
          ),
      dense: widget.dense,
    );
  }
}
