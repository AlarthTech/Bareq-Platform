import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/western_numerals.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../state/booking_review_status_cubit.dart';
import '../state/my_review_cubit.dart';
import '../widgets/star_rating_display.dart';
import '../widgets/star_rating_input.dart';
import '../../../ratings/domain/usecases/rating_usecases.dart';
import '../../../ratings/presentation/rating_refresh_notifier.dart';

class MyReviewPage extends StatefulWidget {
  const MyReviewPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<MyReviewPage> createState() => _MyReviewPageState();
}

class _MyReviewPageState extends State<MyReviewPage> {
  late final MyReviewCubit _cubit;
  int _editRating = 0;
  int? _workerId;
  final _editCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<MyReviewCubit>()..load(widget.bookingId);
  }

  @override
  void dispose() {
    _editCommentController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.translate('deleteReview') ?? 'حذف التقييم'),
        content: Text(
          l10n?.translate('deleteReviewConfirm') ??
              'هل أنت متأكد من حذف تقييمك؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.translate('cancel') ?? 'إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n?.translate('delete') ?? 'حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _cubit.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final locale = l10n?.locale ?? const Locale('ar');

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<MyReviewCubit, MyReviewState>(
        listener: (context, state) {
          if (state is MyReviewLoaded) {
            _workerId = state.review.workerId;
          }
          if (state is MyReviewDeleted) {
            if (_workerId != null) {
              sl<InvalidateRatingCacheUseCase>().forWorker(_workerId!);
              sl<RatingRefreshNotifier>().notifyWorkerInvalidated(_workerId!);
            }
            sl<BookingReviewStatusCubit>().markNotReviewed(widget.bookingId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.translate('reviewDeletedSuccess') ??
                      'تم حذف التقييم.',
                ),
              ),
            );
            context.pop(true);
          } else if (state is MyReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is MyReviewLoaded && state.editing) {
            _editRating = state.review.rating;
            _editCommentController.text = state.review.comment ?? '';
          }
        },
        child: Scaffold(
          appBar: AppTopBar(
            title: l10n?.translate('myReviewTitle') ?? 'عرض تقييمك',
            showBackButton: true,
          ),
          body: BlocBuilder<MyReviewCubit, MyReviewState>(
            builder: (context, state) {
              if (state is MyReviewLoading || state is MyReviewInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is MyReviewEmpty) {
                return Center(
                  child: Text(
                    l10n?.translate('noReviewYet') ?? 'لا يوجد تقييم بعد',
                  ),
                );
              }
              if (state is MyReviewError && state.message.isNotEmpty) {
                return Center(child: Text(state.message));
              }
              if (state is MyReviewDeleting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is! MyReviewLoaded) {
                return const SizedBox.shrink();
              }

              final review = state.review;
              final dateText = WesternNumerals.normalize(
                DateFormat.yMMMd(locale.toString()).format(review.createdAt),
              );

              if (state.editing) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StarRatingInput(
                        value: _editRating,
                        onChanged: (v) => setState(() => _editRating = v),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _editCommentController,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          labelText:
                              l10n?.translate('commentOptional') ??
                              'تعليق (اختياري)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cubit.cancelEditing,
                              child: Text(l10n?.translate('cancel') ?? 'إلغاء'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                if (_editRating < 1) return;
                                await _cubit.update(
                                  rating: _editRating,
                                  comment: _editCommentController.text,
                                );
                                if (_workerId != null && mounted) {
                                  sl<InvalidateRatingCacheUseCase>()
                                      .forWorker(_workerId!);
                                  sl<RatingRefreshNotifier>()
                                      .notifyWorkerInvalidated(_workerId!);
                                }
                              },
                              child: Text(
                                l10n?.translate('saveChanges') ?? 'حفظ',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: StarRatingDisplay(
                        rating: review.rating.toDouble(),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (review.comment?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      Text(
                        review.comment!.trim(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _cubit.startEditing,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n?.translate('editReview') ?? 'تعديل'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: Icon(Icons.delete_outline, color: AppColors.error),
                      label: Text(
                        l10n?.translate('deleteReview') ?? 'حذف التقييم',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
