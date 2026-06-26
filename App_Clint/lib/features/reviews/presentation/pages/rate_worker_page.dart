import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../models/rate_worker_args.dart';
import '../state/booking_review_status_cubit.dart';
import '../state/create_review_cubit.dart';
import '../widgets/star_rating_input.dart';
import '../../../ratings/domain/usecases/rating_usecases.dart';
import '../../../ratings/presentation/rating_refresh_notifier.dart';

class RateWorkerPage extends StatefulWidget {
  const RateWorkerPage({super.key, required this.args});

  final RateWorkerArgs args;

  @override
  State<RateWorkerPage> createState() => _RateWorkerPageState();
}

class _RateWorkerPageState extends State<RateWorkerPage> {
  late final CreateReviewCubit _cubit;
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<CreateReviewCubit>();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String? _validate() {
    final l10n = L10n.of(context);
    if (_rating < 1 || _rating > 5) {
      return l10n?.translate('selectRatingRequired') ??
          'يرجى اختيار التقييم';
    }
    final comment = _commentController.text.trim();
    if (comment.length > 1000) {
      return l10n?.translate('commentTooLong') ?? 'التعليق طويل جداً';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    await _cubit.submit(
      bookingId: widget.args.bookingId,
      workerId: widget.args.workerId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );
  }

  void _onSuccess(BuildContext context) {
    final l10n = L10n.of(context);
    sl<InvalidateRatingCacheUseCase>().forWorker(
      widget.args.workerId,
      companyId: widget.args.companyId,
    );
    sl<RatingRefreshNotifier>().notifyWorkerInvalidated(
      widget.args.workerId,
      companyId: widget.args.companyId,
    );
    sl<BookingReviewStatusCubit>().markReviewed(widget.args.bookingId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.translate('reviewSubmittedSuccess') ??
              'شكراً! تم إرسال تقييمك بنجاح.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop(true);
  }

  void _onAlreadyReviewed(BuildContext context) {
    context.pushReplacement(
      AppStrings.myReviewRoute(widget.args.bookingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<CreateReviewCubit, CreateReviewState>(
        listener: (context, state) {
          if (state is CreateReviewSuccess) {
            _onSuccess(context);
          } else if (state is CreateReviewError) {
            if (state.message.contains('تم التقييم على هذا الحجز مسبقاً')) {
              sl<BookingReviewStatusCubit>()
                  .markReviewed(widget.args.bookingId);
              _onAlreadyReviewed(context);
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppTopBar(
            title: l10n?.translate('rateWorkerTitle') ?? 'تقييم العاملة',
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${l10n?.translate('rateWorkerHeader') ?? 'تقييم العاملة:'} ${widget.args.workerName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (widget.args.companyName?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.args.companyName!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n?.translate('yourRating') ?? 'تقييمك',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                StarRatingInput(
                  value: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.translate('commentOptional') ?? 'تعليق (اختياري)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 1000,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText:
                        l10n?.translate('reviewCommentHint') ??
                        'شاركنا تجربتك...',
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<CreateReviewCubit, CreateReviewState>(
                  builder: (context, state) {
                    final loading = state is CreateReviewLoading;
                    final canSubmit = _rating >= 1 && !loading;
                    return FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n?.translate('submitReview') ??
                                  'إرسال التقييم',
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
