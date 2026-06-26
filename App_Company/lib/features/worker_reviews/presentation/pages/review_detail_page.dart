import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../../core/widgets/star_rating_display.dart';
import '../../domain/usecases/get_review_by_id.dart';
import '../../domain/entities/review.dart';

class ReviewDetailPage extends StatefulWidget {
  const ReviewDetailPage({super.key, required this.reviewId});

  final int reviewId;

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  late final Future<Review?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadReview();
  }

  Future<Review?> _loadReview() async {
    final result = await getIt<GetReviewByIdUseCase>()(widget.reviewId);
    return result.fold((_) => null, (review) => review);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'تفاصيل المراجعة',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Review?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(AppTheme.spacing16),
              child: LoadingShimmerWidget(
                height: 220,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            );
          }

          final review = snapshot.data;
          if (review == null) {
            return ErrorStateWidget(
              message: 'تعذر تحميل المراجعة',
              onRetry: () => setState(() => _future = _loadReview()),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StarRatingDisplay(
                    rating: review.rating.toDouble(),
                    showCount: false,
                    starSize: 24,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  _DetailRow(label: 'العميل', value: review.userName ?? 'عميل'),
                  _DetailRow(label: 'العاملة', value: review.workerName ?? '—'),
                  _DetailRow(
                    label: 'رقم الحجز',
                    value: '#${review.bookingId}',
                  ),
                  _DetailRow(
                    label: 'التاريخ',
                    value: DateFormatter.formatDisplayDate(review.createdAt),
                  ),
                  if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'التعليق',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.comment!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.gray700,
                            height: 1.5,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray500,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray900,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
