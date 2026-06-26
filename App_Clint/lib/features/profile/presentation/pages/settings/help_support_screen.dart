import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/l10n_helper.dart';
import '../../../../../core/widgets/common/app_top_bar.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _supportEmail = 'support@bareq.ly';

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.translate(context, 'emailCopied')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('helpAndSupport') ?? 'Help & Support',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _faqTile(
            context,
            l10n?.translate('faqBooking') ?? 'How do I book a maid?',
            l10n?.translate('faqBookingAnswer') ??
                'Open a worker profile, tap Book Now, choose the shift and dates, then confirm.',
          ),
          _faqTile(
            context,
            l10n?.translate('faqCancel') ?? 'How do I cancel a booking?',
            l10n?.translate('faqCancelAnswer') ??
                'Go to Bookings, open the booking, and tap Cancel while it is still pending.',
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.primary),
            title: Text(l10n?.translate('contactSupport') ?? 'Contact support'),
            subtitle: const Text(_supportEmail),
            onTap: () => _copyEmail(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqTile(BuildContext context, String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        title: Text(
          q,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                a,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
