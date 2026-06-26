import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status_codes.dart';

/// Wallet reserve/capture messaging for customer booking detail.
class BookingWalletStatusCard extends StatelessWidget {
  const BookingWalletStatusCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    if (!booking.isWalletPayment) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final messages = <String>[];

    if (booking.status == BookingStatusCodes.canceled) {
      if (booking.walletAmountCaptured) {
        messages.add(
          l10n?.translate('walletHoldRefundedHint') ??
              'تم استرداد المبلغ إلى المحفظة',
        );
      } else if (booking.walletAmountReserved) {
        messages.add(
          l10n?.translate('walletHoldReleasedHint') ??
              'تم إرجاع المبلغ المحجوز',
        );
      }
    } else if (booking.walletAmountCaptured) {
      messages.add(
        l10n?.translate('walletHoldCapturedHint') ??
            'تم خصم المبلغ من المحفظة',
      );
    } else if (booking.walletAmountReserved) {
      if (booking.status == BookingStatusCodes.pending) {
        messages.add(
          l10n?.translate('walletBookingReservedBadge') ??
              'محجوز من المحفظة',
        );
      }
      messages.add(
        l10n?.translate('walletHoldReservedHint') ??
            'المبلغ محجوز من محفظتك',
      );
      if (booking.status == BookingStatusCodes.onTheWay &&
          !booking.isWorkerArrivalConfirmed) {
        messages.add(
          l10n?.translate('walletHoldCaptureOnConfirmHint') ??
              'يُخصم المبلغ عند تأكيد وصول العاملة أو عند إتمام الخدمة',
        );
      }
    }

    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.translate('walletPayment') ?? 'دفع المحفظة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < messages.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Text(
              messages[i],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
