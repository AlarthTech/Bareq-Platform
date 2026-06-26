import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/legal_document_section.dart';

/// Reusable card for a single section inside a legal document.
class LegalSection extends StatelessWidget {
  final LegalDocumentSection section;
  final bool isArabic;
  final bool isDark;

  const LegalSection({
    super.key,
    required this.section,
    required this.isArabic,
    required this.isDark,
  });

  TextStyle _bodyStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge;
    final color = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    if (isArabic) {
      return GoogleFonts.almarai(
        textStyle: base?.copyWith(color: color, height: 1.65, fontSize: 15),
      );
    }
    return base?.copyWith(color: color, height: 1.65, fontSize: 15) ??
        TextStyle(color: color, height: 1.65, fontSize: 15);
  }

  TextStyle _titleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium;
    final color = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    if (isArabic) {
      return GoogleFonts.almarai(
        textStyle: base?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
    }
    return base?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ) ??
        TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16);
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkSurfaceVariant : AppColors.border;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.55)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: _titleStyle(context)),
          if (section.paragraphs.isNotEmpty) const SizedBox(height: 10),
          ...section.paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p, style: _bodyStyle(context)),
            ),
          ),
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...section.bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        top: 7,
                        end: isArabic ? 0 : 10,
                        start: isArabic ? 10 : 0,
                      ),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(child: Text(b, style: _bodyStyle(context))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
