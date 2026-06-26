import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../localization/l10n_helper.dart';

/// Shows a localized snackbar for features not yet available.
void showComingSoonSnackBar(BuildContext context, {String? messageKey}) {
  final l10n = L10n.of(context);
  final message =
      l10n?.translate(messageKey ?? 'comingSoonMessage') ??
      'This feature is coming soon.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 3),
      ),
    );
}

/// Non-interactive chip for disabled actions.
class ComingSoonChip extends StatelessWidget {
  const ComingSoonChip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        l10n?.translate('comingSoon') ?? 'Coming soon',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
