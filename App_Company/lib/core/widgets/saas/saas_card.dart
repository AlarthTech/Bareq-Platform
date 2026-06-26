import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Soft-shadow surface card — no outline border (corporate SaaS).
class SaasCard extends StatelessWidget {
  const SaasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacing20),
    this.onTap,
    this.color,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppTheme.radiusCard;
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(r),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: content,
      ),
    );
  }
}

/// Compact KPI tile for dashboard grids.
class SaasKpiTile extends StatelessWidget {
  const SaasKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.accent = AppTheme.primaryTeal,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SaasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.gray900,
                      height: 1.1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            label,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray800,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
