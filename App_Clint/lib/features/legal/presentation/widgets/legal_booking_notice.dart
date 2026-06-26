import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';

/// Small legal notice shown on booking confirmation (step 3).
class LegalBookingNotice extends StatelessWidget {
  const LegalBookingNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n?.isRTL ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text =
        l10n?.translate('bookingLegalNotice') ??
        'By confirming the booking, you agree to the application Terms & Conditions and Privacy Policy.';
    final color =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final style = isArabic
        ? GoogleFonts.almarai(
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  height: 1.5,
                  fontSize: 12,
                ),
          )
        : Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              height: 1.5,
              fontSize: 12,
            );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        textAlign: isArabic ? TextAlign.right : TextAlign.left,
        style: style,
      ),
    );
  }
}
