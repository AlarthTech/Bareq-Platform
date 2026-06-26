import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../localization/l10n_helper.dart';

/// RTL-aware text-only back control — no arrow icons.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.label,
    this.textColor,
  });

  final VoidCallback? onPressed;
  final String? label;
  final Color? textColor;

  static bool isRtl(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  /// Arabic: رجوع — English: Back
  static String labelFor(BuildContext context) {
    return isRtl(context) ? 'رجوع' : (L10n.of(context)?.translate('back') ?? 'Back');
  }

  void _handlePressed(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.textPrimary;
    return Semantics(
      button: true,
      label: label ?? labelFor(context),
      child: TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _handlePressed(context),
      child: Text(
        label ?? labelFor(context),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    ),
    );
  }

  /// AppBar [leading] on the start edge (left LTR, right RTL).
  static Widget appBarLeading(
    BuildContext context, {
    VoidCallback? onPressed,
    String? label,
    Color? textColor,
  }) {
    return AppBackButton(
      onPressed: onPressed,
      label: label,
      textColor: textColor,
    );
  }
}

/// Alias for [AppBackButton].
typedef AppBackTextButton = AppBackButton;
