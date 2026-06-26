import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/l10n_helper.dart';

/// Animated Booking Success Dialog
/// Shows a beautiful success animation when booking is confirmed
class BookingSuccessDialog extends StatefulWidget {
  final String bookingDate;

  const BookingSuccessDialog({
    super.key,
    required this.bookingDate,
  });

  @override
  State<BookingSuccessDialog> createState() => _BookingSuccessDialogState();
}

class _BookingSuccessDialogState extends State<BookingSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for the dialog container
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    // Check mark animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOut,
    );

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start animations in sequence
    _startAnimations();
  }

  void _startAnimations() {
    // Start scale animation
    _scaleController.forward();

    // Start check mark animation after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _checkController.forward();
      }
    });

    // Start fade animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon with Animation
              _buildSuccessIcon(),
              const SizedBox(height: 24),

              // Success Message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      l10n?.translate('bookingConfirmed') ?? 'Booking Confirmed!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n?.translate('yourBookingHasBeenConfirmedFor') ?? 'Your booking has been confirmed for',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.bookingDate,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // OK Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n?.translate('ok') ?? 'OK',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated circle background
          ScaleTransition(
            scale: _checkAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Check mark icon
          AnimatedBuilder(
            animation: _checkController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(50, 50),
                painter: _CheckMarkPainter(
                  progress: _checkAnimation.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated check mark
class _CheckMarkPainter extends CustomPainter {
  final double progress;

  _CheckMarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Draw check mark
    // Start point (bottom left of check)
    final startX = size.width * 0.2;
    final startY = size.height * 0.5;

    // Middle point (center)
    final midX = size.width * 0.45;
    final midY = size.height * 0.7;

    // End point (top right of check)
    final endX = size.width * 0.8;
    final endY = size.height * 0.3;

    if (progress > 0.0) {
      // Draw first part of check (from start to middle)
      if (progress < 0.5) {
        final firstProgress = progress * 2;
        path.moveTo(startX, startY);
        path.lineTo(
          startX + (midX - startX) * firstProgress,
          startY + (midY - startY) * firstProgress,
        );
      } else {
        // Draw complete first part
        path.moveTo(startX, startY);
        path.lineTo(midX, midY);

        // Draw second part of check (from middle to end)
        final secondProgress = (progress - 0.5) * 2;
        path.lineTo(
          midX + (endX - midX) * secondProgress,
          midY + (endY - midY) * secondProgress,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

