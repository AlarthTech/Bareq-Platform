import 'package:flutter/material.dart';

/// Subtle press feedback (scale ~0.97) for cards and list rows.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.minScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double minScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap != null) _c.forward();
      },
      onTapCancel: () => _c.reverse(),
      onTap: () {
        _c.reverse();
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: widget.minScale).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
        ),
        child: widget.child,
      ),
    );
  }
}
