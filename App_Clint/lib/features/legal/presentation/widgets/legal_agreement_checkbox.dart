import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../registration_legal_read_tracker.dart';

/// Registration agreement with tappable Terms & Privacy links.
class LegalAgreementCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final RegistrationLegalReadTracker readTracker;

  const LegalAgreementCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.readTracker,
  });

  @override
  State<LegalAgreementCheckbox> createState() => _LegalAgreementCheckboxState();
}

class _LegalAgreementCheckboxState extends State<LegalAgreementCheckbox> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    widget.readTracker.addListener(_onTrackerChanged);
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    widget.readTracker.removeListener(_onTrackerChanged);
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _onTrackerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openTerms() async {
    await context.pushNamed(
      'terms-conditions',
      extra: widget.readTracker,
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPrivacy() async {
    await context.pushNamed(
      'privacy-policy',
      extra: widget.readTracker,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n?.isRTL ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final linkColor = AppColors.primary;
    final readLinkColor = AppColors.success;

    final prefix = l10n?.translate('legalAgreePrefix') ?? 'I agree to the ';
    final connector = l10n?.translate('legalAgreeConnector') ?? ' and ';
    final termsLabel =
        l10n?.translate('termsAndConditions') ?? 'Terms & Conditions';
    final privacyLabel = l10n?.translate('privacyPolicy') ?? 'Privacy Policy';
    final canCheck = widget.readTracker.canAgree;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadStatusRow(
          termsRead: widget.readTracker.termsFullyRead,
          privacyRead: widget.readTracker.privacyFullyRead,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: widget.value,
              onChanged: canCheck ? widget.onChanged : null,
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: RichText(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.45,
                        ),
                    children: [
                      TextSpan(text: prefix),
                      TextSpan(
                        text: termsLabel,
                        style: TextStyle(
                          color: widget.readTracker.termsFullyRead
                              ? readLinkColor
                              : linkColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _termsRecognizer,
                      ),
                      TextSpan(text: connector),
                      TextSpan(
                        text: privacyLabel,
                        style: TextStyle(
                          color: widget.readTracker.privacyFullyRead
                              ? readLinkColor
                              : linkColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _privacyRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadStatusRow extends StatelessWidget {
  final bool termsRead;
  final bool privacyRead;

  const _ReadStatusRow({
    required this.termsRead,
    required this.privacyRead,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final termsStatus = l10n?.translate('legalTermsReadStatus') ??
        'Terms & Conditions';
    final privacyStatus = l10n?.translate('legalPrivacyReadStatus') ??
        'Privacy Policy';

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _StatusChip(label: termsStatus, done: termsRead),
          _StatusChip(label: privacyStatus, done: privacyRead),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool done;

  const _StatusChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
