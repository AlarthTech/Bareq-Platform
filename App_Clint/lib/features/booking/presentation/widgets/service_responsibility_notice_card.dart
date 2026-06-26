import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';

/// Expandable service responsibility notice with required acceptance checkbox.
class ServiceResponsibilityNoticeCard extends StatelessWidget {
  const ServiceResponsibilityNoticeCard({
    super.key,
    required this.accepted,
    required this.onAcceptedChanged,
    this.showValidationError = false,
    this.embeddedInScroll = false,
  });

  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;
  final bool showValidationError;
  final bool embeddedInScroll;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n?.isRTL ?? true;
    final title =
        l10n?.translate('serviceResponsibilityNoticeTitle') ??
        'Service Responsibility Notice';

    TextStyle bodyStyle(Color color) {
      final base = Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            height: 1.55,
            fontSize: 13,
          );
      if (isArabic) {
        return GoogleFonts.almarai(textStyle: base);
      }
      return base ?? const TextStyle(fontSize: 13, height: 1.55);
    }

    final bodyColor = AppColors.textPrimary;
    final secondaryColor = AppColors.textSecondary;

    return Container(
      margin: embeddedInScroll
          ? const EdgeInsets.only(bottom: 8)
          : const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              leading: Icon(
                Icons.info_outline,
                color: AppColors.warning.withValues(alpha: 0.95),
              ),
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              iconColor: AppColors.warning,
              collapsedIconColor: AppColors.textSecondary,
              children: [
                Text(
                  l10n?.translate('serviceResponsibilityNoticeP1') ?? '',
                  style: bodyStyle(bodyColor),
                  textAlign: isArabic ? TextAlign.right : TextAlign.start,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n?.translate('serviceResponsibilityNoticeP2') ?? '',
                  style: bodyStyle(bodyColor),
                  textAlign: isArabic ? TextAlign.right : TextAlign.start,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n?.translate('serviceResponsibilityNoticeIssuesIntro') ??
                      '',
                  style: bodyStyle(bodyColor).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: isArabic ? TextAlign.right : TextAlign.start,
                ),
                const SizedBox(height: 8),
                ..._bulletKeys.map(
                  (key) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: bodyStyle(secondaryColor),
                        ),
                        Expanded(
                          child: Text(
                            l10n?.translate(key) ?? '',
                            style: bodyStyle(secondaryColor),
                            textAlign: isArabic ? TextAlign.right : TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n?.translate('serviceResponsibilityNoticeP3') ?? '',
                  style: bodyStyle(bodyColor),
                  textAlign: isArabic ? TextAlign.right : TextAlign.start,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n?.translate('serviceResponsibilityNoticeP4') ?? '',
                  style: bodyStyle(bodyColor),
                  textAlign: isArabic ? TextAlign.right : TextAlign.start,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            value: accepted,
            onChanged: (value) => onAcceptedChanged(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            activeColor: AppColors.primary,
            title: Text(
              l10n?.translate('serviceResponsibilityNoticeCheckbox') ?? '',
              style: bodyStyle(bodyColor).copyWith(fontSize: 12),
            ),
          ),
          if (showValidationError && !accepted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l10n?.translate('serviceResponsibilityNoticeRequired') ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: isArabic ? TextAlign.right : TextAlign.start,
              ),
            ),
        ],
      ),
    );
  }

  static const _bulletKeys = [
    'serviceResponsibilityNoticeIssue1',
    'serviceResponsibilityNoticeIssue2',
    'serviceResponsibilityNoticeIssue3',
    'serviceResponsibilityNoticeIssue4',
    'serviceResponsibilityNoticeIssue5',
  ];
}
