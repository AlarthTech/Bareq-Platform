import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum KpiEmphasis { highlight, normal, muted }

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final KpiEmphasis emphasis;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.emphasis = KpiEmphasis.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMuted = emphasis == KpiEmphasis.muted;
    final isHighlight = emphasis == KpiEmphasis.highlight;

    final borderColor = isHighlight
        ? AppTheme.primaryTeal.withValues(alpha: 0.35)
        : Colors.transparent;
    final bg = isHighlight
        ? AppTheme.primaryTeal.withValues(alpha: 0.06)
        : (isMuted ? AppTheme.gray50 : Colors.white);

    final valueStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 26,
          height: 1.1,
          color: isMuted ? AppTheme.gray500 : AppTheme.gray900,
        );

    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isMuted ? AppTheme.gray400 : AppTheme.gray600,
          fontWeight: FontWeight.w500,
        );

    final iconClr = iconColor ?? AppTheme.primaryTeal;
    final iconOpacity = isMuted ? 0.45 : 1.0;

    return Material(
      color: bg,
      elevation: isMuted ? 0 : 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: borderColor,
              width: isHighlight ? 1.5 : 1,
            ),
            boxShadow: isMuted ? null : AppTheme.softShadow,
            color: bg,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    if (icon != null)
                      Opacity(
                        opacity: iconOpacity,
                        child: Icon(
                          icon,
                          size: 20,
                          color: iconClr,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  value,
                  style: valueStyle,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  title,
                  style: labelStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
