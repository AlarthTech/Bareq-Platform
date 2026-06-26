import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/entities/review_ratings.dart';
import '../../domain/entities/review_request.dart';
import '../../domain/usecases/submit_review_usecase.dart';
import 'rating_complete_dialog.dart';

/// Rating Bottom Sheet
/// Allows users to rate completed bookings with multiple KPIs
class RatingBottomSheet extends StatefulWidget {
  final String maidName;
  final String bookingId;
  final int workerId;
  final int serviceId;
  final BuildContext? parentContext;

  const RatingBottomSheet({
    super.key,
    required this.maidName,
    required this.bookingId,
    required this.workerId,
    required this.serviceId,
    this.parentContext,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

/// Star rating widget with animation
class _AnimatedStar extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const _AnimatedStar({
    required this.isSelected,
    required this.onTap,
    this.size = 36,
  });

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.isSelected ? Icons.star : Icons.star_border,
              size: widget.size,
              color: widget.isSelected ? AppColors.primary : AppColors.border,
            ),
          );
        },
      ),
    );
  }
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  // Rating values for each KPI (1-5)
  int _punctuality = 0;
  int _cleaningQuality = 0;
  int _attentionToDetails = 0;
  int _professionalism = 0;
  int _respectAndAttitude = 0;
  int _followingInstructions = 0;
  int _speedAndEfficiency = 0;
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();

  double get _overallRating {
    final ratings = [
      _punctuality,
      _cleaningQuality,
      _attentionToDetails,
      _professionalism,
      _respectAndAttitude,
      _followingInstructions,
      _speedAndEfficiency,
    ];
    final validRatings = ratings.where((r) => r > 0).toList();
    if (validRatings.isEmpty) return 0.0;
    return validRatings.reduce((a, b) => a + b) / validRatings.length;
  }

  bool get _canSubmit {
    return _punctuality > 0 &&
        _cleaningQuality > 0 &&
        _attentionToDetails > 0 &&
        _professionalism > 0 &&
        _respectAndAttitude > 0 &&
        _followingInstructions > 0 &&
        _speedAndEfficiency > 0;
  }

  Future<void> _submitRating() async {
    if (!_canSubmit || _isSubmitting) return;

    final dialogContext = widget.parentContext ?? context;
    final snackContext = dialogContext;
    setState(() {
      _isSubmitting = true;
    });

    final bookingId = int.tryParse(widget.bookingId) ?? 0;
    final reviewRequest = ReviewRequest(
      bookingId: bookingId,
      workerId: widget.workerId,
      serviceId: widget.serviceId,
      overallRating: _overallRating.round(),
      comment: _commentController.text.trim(),
      ratings: ReviewRatings(
        punctuality: _punctuality,
        cleaningQuality: _cleaningQuality,
        attentionToDetail: _attentionToDetails,
        professionalism: _professionalism,
        respectAndBehavior: _respectAndAttitude,
        followingInstructions: _followingInstructions,
        speedAndEfficiency: _speedAndEfficiency,
      ),
    );

    final submitReviewUseCase = sl<SubmitReviewUseCase>();
    final result = await submitReviewUseCase(reviewRequest);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    result.fold(
      (failure) {
        _showSnack(snackContext, failure.message);
      },
      (_) async {
        if (mounted) {
          Navigator.of(context).pop();
        }
        await Future.delayed(const Duration(milliseconds: 300));
        if (dialogContext.mounted) {
          showDialog(
            context: dialogContext,
            barrierColor: Colors.black.withOpacity(0.5),
            barrierDismissible: false,
            builder: (context) => const RatingCompleteDialog(),
          );
        }
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  l10n?.translate('rateYourExperience') ??
                      'Rate Your Experience',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (l10n?.translate('rateMaidService') ??
                          'How was your experience with {name}?')
                      .replaceAll('{name}', widget.maidName),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Rating KPIs
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildRatingKPI(
                    context,
                    title: l10n?.translate('punctuality') ?? 'Punctuality',
                    hint:
                        l10n?.translate('punctualityHint') ??
                        'Did the maid arrive on time?',
                    rating: _punctuality,
                    onRatingChanged: (rating) {
                      setState(() {
                        _punctuality = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildRatingKPI(
                    context,
                    title:
                        l10n?.translate('cleaningQuality') ??
                        'Cleaning Quality',
                    hint:
                        l10n?.translate('cleaningQualityHint') ??
                        'How clean was the house after the service?',
                    rating: _cleaningQuality,
                    onRatingChanged: (rating) {
                      setState(() {
                        _cleaningQuality = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildRatingKPI(
                    context,
                    title:
                        l10n?.translate('attentionToDetails') ??
                        'Attention to Details',
                    hint:
                        l10n?.translate('attentionToDetailsHint') ??
                        'Corners, bathrooms, kitchen, hard-to-reach places',
                    rating: _attentionToDetails,
                    onRatingChanged: (rating) {
                      setState(() {
                        _attentionToDetails = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildRatingKPI(
                    context,
                    title:
                        l10n?.translate('professionalism') ?? 'Professionalism',
                    hint:
                        l10n?.translate('professionalismHint') ??
                        'Behavior, seriousness, and work ethics',
                    rating: _professionalism,
                    onRatingChanged: (rating) {
                      setState(() {
                        _professionalism = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildRatingKPI(
                    context,
                    title:
                        l10n?.translate('respectAndAttitude') ??
                        'Respect & Attitude',
                    hint:
                        l10n?.translate('respectAndAttitudeHint') ??
                        'Politeness and respectful behavior inside the home',
                    rating: _respectAndAttitude,
                    onRatingChanged: (rating) {
                      setState(() {
                        _respectAndAttitude = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildRatingKPI(
                    context,
                    title:
                        l10n?.translate('followingInstructions') ??
                        'Following Instructions',
                    hint:
                        l10n?.translate('followingInstructionsHint') ??
                        'Did the maid follow your specific requests?',
                    rating: _followingInstructions,
                    onRatingChanged: (rating) {
                      setState(() {
                        _followingInstructions = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildRatingKPI(
                    context,
                    title:
                        l10n?.translate('speedAndEfficiency') ??
                        'Speed & Efficiency',
                    hint:
                        l10n?.translate('speedAndEfficiencyHint') ??
                        'Finished tasks in a reasonable time',
                    rating: _speedAndEfficiency,
                    onRatingChanged: (rating) {
                      setState(() {
                        _speedAndEfficiency = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Overall Rating
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n?.translate('overallRating') ?? 'Overall Rating',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(5, (index) {
                              final starValue = index + 1;
                              final isFilled =
                                  starValue <= _overallRating.round();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isFilled ? Icons.star : Icons.star_border,
                                    key: ValueKey('$isFilled-$index'),
                                    size: 32,
                                    color:
                                        isFilled
                                            ? AppColors.primary
                                            : AppColors.border,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _overallRating > 0
                              ? _overallRating.toStringAsFixed(1)
                              : '-',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText:
                          l10n?.translate('shareFeedback') ??
                          'Share your experience (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Submit Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.border.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _canSubmit && !_isSubmitting ? _submitRating : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            l10n?.translate('submitRating') ?? 'Submit Rating',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildRatingKPI(
    BuildContext context, {
    required String title,
    required String hint,
    required int rating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= rating;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _AnimatedStar(
                isSelected: isSelected,
                onTap: () => onRatingChanged(starValue),
                size: 36,
              ),
            );
          }),
        ),
      ],
    );
  }
}
