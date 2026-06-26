import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/status_helper.dart';

class StatusBadge extends StatelessWidget {
  final int status;
  final String? customText;
  final String? badgeType; // 'success', 'warning', 'danger', 'info', 'neutral'

  const StatusBadge({
    super.key,
    required this.status,
    this.customText,
    this.badgeType,
  });

  @override
  Widget build(BuildContext context) {
    final text = customText ?? StatusHelper.getStatusText(status);
    final type = badgeType ?? StatusHelper.getStatusBadgeType(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(type),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _getTextColor(type),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor(String type) {
    switch (type) {
      case 'success':
        return AppTheme.successGreen.withOpacity(0.1);
      case 'warning':
        return AppTheme.warningAmber.withOpacity(0.1);
      case 'danger':
        return AppTheme.dangerRed.withOpacity(0.1);
      case 'info':
        return AppTheme.infoBlue.withOpacity(0.1);
      default:
        return AppTheme.gray200;
    }
  }

  Color _getTextColor(String type) {
    switch (type) {
      case 'success':
        return AppTheme.successGreen;
      case 'warning':
        return AppTheme.warningAmber;
      case 'danger':
        return AppTheme.dangerRed;
      case 'info':
        return AppTheme.infoBlue;
      default:
        return AppTheme.gray700;
    }
  }
}
