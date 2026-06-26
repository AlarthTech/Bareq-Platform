import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom page transitions for smooth, gentle animations
/// Designed to match the Modern Soft Feminine aesthetic
class CustomPageTransitions {
  /// Smooth fade transition - gentle and elegant
  static Page<T> fadeTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Smooth slide transition from right - for forward navigation
  static Page<T> slideFromRightTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Smooth slide transition from left - for backward navigation
  static Page<T> slideFromLeftTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Gentle scale and fade transition - soft and welcoming
  static Page<T> scaleFadeTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeOut).animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut))
                .animate(animation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  /// Smooth horizontal slide for tab navigation (no-opacity change for continuity)
  static Page<T> horizontalSlideTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    bool slideLeft = false,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset = slideLeft ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
        var tween = Tween(begin: offset, end: Offset.zero).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

/// Custom page wrapper for transitions
class CustomTransitionPage<T> extends Page<T> {
  final Widget child;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) transitionsBuilder;
  final Duration transitionDuration;

  const CustomTransitionPage({
    required super.key,
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: transitionsBuilder,
    );
  }
}






