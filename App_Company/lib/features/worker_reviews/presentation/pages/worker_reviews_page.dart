import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/rating_formatter.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../../core/widgets/star_rating_display.dart';
import '../state/worker_reviews_cubit.dart';
import '../state/worker_reviews_state.dart';
import '../widgets/review_list_item.dart';

class WorkerReviewsPage extends StatefulWidget {
  const WorkerReviewsPage({
    super.key,
    required this.workerId,
    required this.workerName,
    this.profileImage,
  });

  final int workerId;
  final String workerName;
  final String? profileImage;

  @override
  State<WorkerReviewsPage> createState() => _WorkerReviewsPageState();
}

class _WorkerReviewsPageState extends State<WorkerReviewsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<WorkerReviewsCubit>().load(widget.workerId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    context.read<WorkerReviewsCubit>().loadNextPage(widget.workerId);
  }

  Future<void> _refresh() {
    return context.read<WorkerReviewsCubit>().refresh(widget.workerId);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveApiUrl(widget.profileImage);

    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'تقييمات ${widget.workerName}',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<WorkerReviewsCubit, WorkerReviewsState>(
        builder: (context, state) {
          if (state is WorkerReviewsLoading) {
            return ListView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              children: List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LoadingShimmerWidget(
                    height: 88,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                ),
              ),
            );
          }

          if (state is WorkerReviewsError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<WorkerReviewsCubit>().load(widget.workerId),
            );
          }

          if (state is! WorkerReviewsLoaded) {
            return const SizedBox.shrink();
          }

          final summary = state.summary;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppTheme.primaryTeal,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.gray100,
                        backgroundImage: imageUrl != null
                            ? CachedNetworkImageProvider(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? Text(
                                widget.workerName.isNotEmpty
                                    ? widget.workerName[0]
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryTeal,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.workerName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            if (summary.hasReviews) ...[
                              Text(
                                RatingFormatter.formatAverage(summary.averageRating),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              StarRatingDisplay(
                                rating: summary.averageRating,
                                reviewCount: summary.totalReviews,
                                starSize: 18,
                              ),
                              Text(
                                '${summary.totalReviews} تقييم',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.gray600,
                                    ),
                              ),
                            ] else
                              Text(
                                'لم يتلقَ هذا العامل أي تقييمات بعد',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.gray500,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                if (state.reviews.isEmpty && !summary.hasReviews)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text('لم يتلقَ هذا العامل أي تقييمات بعد'),
                    ),
                  )
                else
                  ...state.reviews.map(
                    (review) => ReviewListItem(
                      review: review,
                      onTap: () => context.push(AppRoutes.reviewDetail(review.id)),
                    ),
                  ),
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.spacing16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
