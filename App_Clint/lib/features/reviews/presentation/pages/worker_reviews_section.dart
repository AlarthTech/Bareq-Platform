import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../ratings/domain/entities/rating_summary.dart';
import '../../../ratings/domain/usecases/rating_usecases.dart';
import '../../../ratings/presentation/rating_refresh_notifier.dart';
import '../../../ratings/presentation/widgets/rating_summary_row.dart';
import '../state/worker_reviews_cubit.dart';
import '../widgets/review_card.dart';

class WorkerReviewsSection extends StatefulWidget {
  const WorkerReviewsSection({super.key, required this.workerId});

  final int workerId;

  @override
  State<WorkerReviewsSection> createState() => _WorkerReviewsSectionState();
}

class _WorkerReviewsSectionState extends State<WorkerReviewsSection> {
  late final WorkerReviewsCubit _cubit;
  late final RatingRefreshNotifier _refreshNotifier;
  WorkerRatingSummary? _summary;
  bool _summaryLoading = true;

  @override
  void initState() {
    super.initState();
    _cubit = sl<WorkerReviewsCubit>()..load(widget.workerId);
    _refreshNotifier = sl<RatingRefreshNotifier>();
    _refreshNotifier.addListener(_onRefreshSignal);
    _loadSummary();
  }

  void _onRefreshSignal() {
    if (_refreshNotifier.workerId == widget.workerId) {
      _loadSummary(force: true);
      _cubit.load(widget.workerId);
    }
  }

  @override
  void didUpdateWidget(covariant WorkerReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workerId != widget.workerId) {
      _loadSummary(force: true);
      _cubit.load(widget.workerId);
    }
  }

  Future<void> _loadSummary({bool force = false}) async {
    if (force) {
      sl<InvalidateRatingCacheUseCase>().forWorker(widget.workerId);
    }
    if (!mounted) return;
    setState(() => _summaryLoading = true);

    final result =
        await sl<GetWorkerRatingSummaryUseCase>()(widget.workerId);
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        _summary = WorkerRatingSummary(
          workerId: widget.workerId,
          averageRating: 0,
          totalReviews: 0,
        );
        _summaryLoading = false;
      }),
      (summary) => setState(() {
        _summary = summary;
        _summaryLoading = false;
      }),
    );
  }

  @override
  void dispose() {
    _refreshNotifier.removeListener(_onRefreshSignal);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final summary = _summary ??
        WorkerRatingSummary(
          workerId: widget.workerId,
          averageRating: 0,
          totalReviews: 0,
        );

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<WorkerReviewsCubit, WorkerReviewsState>(
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.translate('workerReviews') ?? 'تقييمات العاملة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                if (_summaryLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  RatingSummaryRow(
                    summary: summary,
                    starSize: 22,
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                const SizedBox(height: 12),
                if (state is WorkerReviewsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is WorkerReviewsError)
                  Text(
                    state.message,
                    style: TextStyle(color: AppColors.error),
                  )
                else if (state is WorkerReviewsLoaded) ...[
                  if (state.reviews.isEmpty)
                    Text(
                      l10n?.translate('noReviewsYet') ??
                          'لا توجد تقييمات بعد',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    )
                  else ...[
                    ...state.reviews.map((r) => ReviewCard(review: r)),
                    if (state.hasNextPage)
                      TextButton(
                        onPressed: () =>
                            _cubit.load(widget.workerId, loadMore: true),
                        child: Text(
                          l10n?.translate('loadMoreReviews') ?? 'عرض المزيد',
                        ),
                      ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
