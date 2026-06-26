import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonType { primary, outline, danger, ghost }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.width,
  });
  
  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);
    
    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    
    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    
    return button;
  }
  
  Widget _buildButton(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    
    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.gray300,
            disabledForegroundColor: AppTheme.gray500,
          ),
          child: _buildButtonChild(),
        );
        
      case AppButtonType.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryTeal,
            side: const BorderSide(color: AppTheme.primaryTeal),
            disabledForegroundColor: AppTheme.gray400,
          ).copyWith(
            side: isDisabled
                ? const WidgetStatePropertyAll(BorderSide(color: AppTheme.gray300))
                : const WidgetStatePropertyAll(BorderSide(color: AppTheme.primaryTeal)),
          ),
          child: _buildButtonChild(),
        );
        
      case AppButtonType.danger:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dangerRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.gray300,
            disabledForegroundColor: AppTheme.gray500,
          ),
          child: _buildButtonChild(),
        );
        
      case AppButtonType.ghost:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryTeal,
            disabledForegroundColor: AppTheme.gray400,
          ),
          child: _buildButtonChild(),
        );
    }
  }
  
  Widget _buildButtonChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppTheme.spacing8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
