import 'package:flutter/material.dart';

/// Muted chevron color for navigational rows (#777777).
const Color kBareqNavChevronColor = Color(0xFF777777);

/// Trailing chevron for settings, profile, menus, and tappable rows.
///
/// In RTL: place as the last child of a [Row] or [ListTile.trailing] — it
/// appears on the **left** edge and points **left**.
/// In LTR: appears on the **right** edge and points **right**.
class BareqNavChevron extends StatelessWidget {
  const BareqNavChevron({
    super.key,
    this.size = 20,
    this.color,
    this.padding = const EdgeInsetsDirectional.only(start: 8),
  });

  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;

  static bool isRtl(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  /// Icon pointing into the next screen from the layout trailing edge.
  static IconData trailingIcon(BuildContext context) =>
      isRtl(context) ? Icons.chevron_left : Icons.chevron_right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Icon(
        trailingIcon(context),
        size: size,
        color: color ?? kBareqNavChevronColor,
      ),
    );
  }
}

/// Direction for calendar / pager controls (previous vs next month).
enum BareqStepDirection { back, forward }

/// Chevron for stepping backward or forward (e.g. calendar month header).
class BareqStepChevron extends StatelessWidget {
  const BareqStepChevron({
    super.key,
    required this.direction,
    this.size = 24,
    this.color,
  });

  final BareqStepDirection direction;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = BareqNavChevron.isRtl(context);
    final IconData icon;
    switch (direction) {
      case BareqStepDirection.back:
        icon = rtl ? Icons.chevron_right : Icons.chevron_left;
      case BareqStepDirection.forward:
        icon = rtl ? Icons.chevron_left : Icons.chevron_right;
    }
    return Icon(icon, size: size, color: color);
  }
}
