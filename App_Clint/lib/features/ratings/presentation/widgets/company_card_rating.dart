import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/rating_summary.dart';
import '../../domain/usecases/rating_usecases.dart';
import '../extensions/rating_formatters.dart';
import '../rating_refresh_notifier.dart';

/// Compact company rating for list cards — loads Summary API (cached).
class CompanyCardRating extends StatefulWidget {
  const CompanyCardRating({
    super.key,
    required this.companyId,
    this.iconSize = 12,
    this.fontSize = 11,
  });

  final int companyId;
  final double iconSize;
  final double fontSize;

  @override
  State<CompanyCardRating> createState() => _CompanyCardRatingState();
}

class _CompanyCardRatingState extends State<CompanyCardRating> {
  CompanyRatingSummary? _summary;
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
  void didUpdateWidget(covariant CompanyCardRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _load();
    }
  }

  void _onRefreshSignal() {
    if (_refreshNotifier.companyId == widget.companyId) {
      _load(force: true);
    }
  }

  Future<void> _load({bool force = false}) async {
    if (force) {
      sl<InvalidateRatingCacheUseCase>().forCompany(widget.companyId);
    }
    if (!mounted) return;
    setState(() => _loading = true);

    final result =
        await sl<GetCompanyRatingSummaryUseCase>()(widget.companyId);
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        _summary = CompanyRatingSummary(
          companyId: widget.companyId,
          averageRating: 0,
          totalReviews: 0,
          ratedWorkersCount: 0,
          totalActiveWorkers: 0,
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
      return SizedBox(height: widget.iconSize + 4);
    }

    final summary = _summary ??
        CompanyRatingSummary(
          companyId: widget.companyId,
          averageRating: 0,
          totalReviews: 0,
          ratedWorkersCount: 0,
          totalActiveWorkers: 0,
        );

    if (!summary.hasReviews) {
      return Text(
        reviewCountLabel(0, context),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.85),
              fontSize: widget.fontSize,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: widget.iconSize,
          color: Colors.amber.shade700,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '${summary.averageRating.toStringAsFixed(1)} ${reviewCountLabel(summary.totalReviews, context)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.fontSize,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
