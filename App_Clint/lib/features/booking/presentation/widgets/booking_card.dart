import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../booking_pricing/presentation/widgets/booking_list_price_chip.dart';

/// Booking card: status → worker/company → date/shift → location → price/actions.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.maidName,
    required this.maidAvatarUrl,
    required this.bookingDate,
    required this.bookingTime,
    required this.serviceType,
    required this.status,
    required this.price,
    this.hasPricing = true,
    this.companyName = '',
    this.locationLabel,
    this.onTap,
    this.bookingId,
    required this.workerId,
    required this.serviceId,
    this.hasReview,
    this.onRate,
    this.onViewReview,
  });

  final String maidName;
  final String maidAvatarUrl;
  final String bookingDate;
  final String bookingTime;
  final String serviceType;
  final String companyName;
  final String? locationLabel;
  /// Keys: pending, approved, on_the_way, completed, canceled, rejected
  final String status;
  final double price;
  final bool hasPricing;
  final VoidCallback? onTap;
  final String? bookingId;
  final int workerId;
  final int serviceId;
  /// `null` = review status still loading.
  final bool? hasReview;
  final VoidCallback? onRate;
  final VoidCallback? onViewReview;

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
      case 'confirmed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'on_the_way':
        return AppColors.primary;
      case 'cleaning_started':
        return AppColors.success;
      case 'completed':
        return AppColors.textSecondary;
      case 'canceled':
      case 'cancelled':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(BuildContext context) {
    final l10n = L10n.of(context);
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n?.translate('pending') ?? AppStrings.pending;
      case 'approved':
        return l10n?.translate('approved') ?? 'Approved';
      case 'confirmed':
        return l10n?.translate('confirmed') ?? 'Confirmed';
      case 'rejected':
        return l10n?.translate('rejected') ?? 'Rejected';
      case 'on_the_way':
        return l10n?.translate('onTheWay') ?? 'On the way';
      case 'cleaning_started':
        return l10n?.translate('cleaningStarted') ?? 'Cleaning Started';
      case 'completed':
        return l10n?.translate('completed') ?? 'Completed';
      case 'canceled':
      case 'cancelled':
        return l10n?.translate('canceled') ?? 'Canceled';
      default:
        return status;
    }
  }

  IconData get _statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_outlined;
      case 'approved':
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'on_the_way':
        return Icons.directions_car_outlined;
      case 'cleaning_started':
        return Icons.cleaning_services_outlined;
      case 'completed':
        return Icons.done_all;
      case 'canceled':
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final normalizedStatus = status.toLowerCase();
    final isCompleted = normalizedStatus == 'completed';
    final isCleaningInProgress = normalizedStatus == 'cleaning_started';

    return Semantics(
      button: onTap != null,
      label: '${_getStatusLabel(context)}, $maidName',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.border.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _StatusBadge(
                  label: _getStatusLabel(context),
                  color: _statusColor,
                  icon: _statusIcon,
                  emphasized: isCleaningInProgress,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(maidAvatarUrl: maidAvatarUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          maidName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (companyName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            companyName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          serviceType,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DetailChip(
                      icon: Icons.calendar_today_outlined,
                      label: l10n?.translate('date') ?? AppStrings.date,
                      value: bookingDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DetailChip(
                      icon: Icons.schedule_outlined,
                      label: l10n?.translate('time') ?? AppStrings.time,
                      value: bookingTime,
                    ),
                  ),
                ],
              ),
              if (locationLabel != null && locationLabel!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailChip(
                  icon: Icons.place_outlined,
                  label: l10n?.translate('location') ?? AppStrings.location,
                  value: locationLabel!,
                  fullWidth: true,
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: BookingListPriceChip(
                      totalPrice: price,
                      hasPricing: hasPricing,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCompleted)
                    _buildReviewAction(context, l10n)
                  else
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        l10n?.translate('viewDetails') ?? 'View Details',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewAction(BuildContext context, dynamic l10n) {
    if (hasReview == null) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (hasReview == true) {
      return OutlinedButton.icon(
        onPressed: onViewReview,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: Text(l10n?.translate('viewYourReview') ?? 'عرض تقييمك'),
      );
    }

    return FilledButton.icon(
      onPressed: onRate,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: const Icon(Icons.star_rounded, size: 18),
      label: Text(l10n?.translate('rateWorker') ?? 'قيّم العاملة'),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasized ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: emphasized ? 0.55 : 0.35),
          width: emphasized ? 1.5 : 1,
        ),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.maidAvatarUrl});

  final String maidAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.secondary,
        child:
            ImageUtils.isValidImageUrl(maidAvatarUrl)
                ? ClipOval(
                  child: Image.network(
                    maidAvatarUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => _placeholder(),
                  ),
                )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      'assets/images/worker_placeholder.png',
      width: 48,
      height: 48,
      fit: BoxFit.cover,
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (fullWidth) return content;
    return content;
  }
}
