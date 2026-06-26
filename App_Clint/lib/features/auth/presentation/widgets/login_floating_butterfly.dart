import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class _ButterflySpec {
  const _ButterflySpec({
    required this.phaseOffset,
    required this.xCenterFactor,
    required this.xAmplitudeFactor,
    required this.yBaseFactor,
    required this.yAmplitudeFactor,
    required this.size,
    required this.opacity,
    required this.wingSpeed,
    required this.driftSpeed,
  });

  final double phaseOffset;
  final double xCenterFactor;
  final double xAmplitudeFactor;
  final double yBaseFactor;
  final double yAmplitudeFactor;
  final double size;
  final double opacity;
  final double wingSpeed;
  final double driftSpeed;
}

/// Three soft animated butterflies for the login hero area.
class LoginFloatingButterfly extends StatefulWidget {
  const LoginFloatingButterfly({
    super.key,
    required this.areaHeight,
  });

  /// Height of the flight zone (parent should size this with [Positioned]).
  final double areaHeight;

  @override
  State<LoginFloatingButterfly> createState() => _LoginFloatingButterflyState();
}

class _LoginFloatingButterflyState extends State<LoginFloatingButterfly>
    with SingleTickerProviderStateMixin {
  static const List<_ButterflySpec> _butterflies = [
    _ButterflySpec(
      phaseOffset: 0,
      xCenterFactor: 0.22,
      xAmplitudeFactor: 0.14,
      yBaseFactor: 0.22,
      yAmplitudeFactor: 0.16,
      size: 34,
      opacity: 0.9,
      wingSpeed: 10,
      driftSpeed: 0.85,
    ),
    _ButterflySpec(
      phaseOffset: 2.2,
      xCenterFactor: 0.52,
      xAmplitudeFactor: 0.18,
      yBaseFactor: 0.38,
      yAmplitudeFactor: 0.2,
      size: 40,
      opacity: 0.95,
      wingSpeed: 9,
      driftSpeed: 1.0,
    ),
    _ButterflySpec(
      phaseOffset: 4.5,
      xCenterFactor: 0.78,
      xAmplitudeFactor: 0.12,
      yBaseFactor: 0.18,
      yAmplitudeFactor: 0.14,
      size: 28,
      opacity: 0.82,
      wingSpeed: 11,
      driftSpeed: 1.15,
    ),
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final zoneWidth = constraints.maxWidth;
        final zoneHeight = widget.areaHeight;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final basePhase = _controller.value * 2 * math.pi;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final spec in _butterflies)
                  _buildButterfly(
                    spec: spec,
                    phase: basePhase + spec.phaseOffset,
                    zoneWidth: zoneWidth,
                    zoneHeight: zoneHeight,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildButterfly({
    required _ButterflySpec spec,
    required double phase,
    required double zoneWidth,
    required double zoneHeight,
  }) {
    final halfSize = spec.size * 0.68;
    final x =
        zoneWidth * spec.xCenterFactor +
        math.sin(phase * spec.driftSpeed) *
            (zoneWidth * spec.xAmplitudeFactor) -
        halfSize;
    final y =
        zoneHeight * spec.yBaseFactor +
        math.sin(phase * spec.driftSpeed * 1.2 + 0.8) *
            (zoneHeight * spec.yAmplitudeFactor);
    final wingOpen =
        0.55 + 0.45 * ((math.sin(phase * spec.wingSpeed) + 1) / 2);
    final tilt = 0.1 * math.sin(phase * 0.65 + spec.phaseOffset);
    final bob = 3 * math.sin(phase * 2.1 + spec.phaseOffset);

    return Positioned(
      left: x.clamp(4.0, zoneWidth - spec.size * 1.4),
      top: (y + bob).clamp(0.0, zoneHeight - spec.size),
      child: Transform.rotate(
        angle: tilt,
        child: Opacity(
          opacity: spec.opacity,
          child: _ButterflyArt(size: spec.size, wingOpen: wingOpen),
        ),
      ),
    );
  }
}

class _ButterflyArt extends StatelessWidget {
  const _ButterflyArt({required this.size, required this.wingOpen});

  final double size;
  final double wingOpen;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.35, size),
      painter: _ButterflyPainter(wingOpen: wingOpen.clamp(0.35, 1.0)),
    );
  }
}

class _ButterflyPainter extends CustomPainter {
  _ButterflyPainter({required this.wingOpen});

  final double wingOpen;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final spread = 14.0 * wingOpen;

    final bodyPaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 3.5, height: size.height * 0.42),
        const Radius.circular(2),
      ),
      bodyPaint,
    );

    final antennaPaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center + Offset(-1.5, -size.height * 0.18),
      center + Offset(-4, -size.height * 0.28),
      antennaPaint,
    );
    canvas.drawLine(
      center + Offset(1.5, -size.height * 0.18),
      center + Offset(4, -size.height * 0.28),
      antennaPaint,
    );

    _drawWing(canvas, center, isLeft: true, spread: spread, size: size);
    _drawWing(canvas, center, isLeft: false, spread: spread, size: size);
  }

  void _drawWing(
    Canvas canvas,
    Offset center, {
    required bool isLeft,
    required double spread,
    required Size size,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (isLeft) {
      canvas.scale(-1, 1);
    }

    final wingPath = Path()
      ..moveTo(2, 0)
      ..quadraticBezierTo(spread * 0.35, -size.height * 0.22, spread, -4)
      ..quadraticBezierTo(spread * 1.05, size.height * 0.08, spread * 0.75, size.height * 0.2)
      ..quadraticBezierTo(spread * 0.35, size.height * 0.28, 2, size.height * 0.12)
      ..close();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.95),
          AppColors.primary.withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(0, -size.height * 0.3, spread * 1.2, size.height * 0.5))
      ..style = PaintingStyle.fill;

    canvas.drawPath(wingPath, outerPaint);

    final innerPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final inner = Path()
      ..moveTo(6, 2)
      ..quadraticBezierTo(spread * 0.5, -2, spread * 0.55, 6)
      ..quadraticBezierTo(spread * 0.45, 14, 8, 12)
      ..close();
    canvas.drawPath(inner, innerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ButterflyPainter oldDelegate) =>
      oldDelegate.wingOpen != wingOpen;
}
