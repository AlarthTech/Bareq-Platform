import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_app_bar.dart';
import 'app_bottom_nav_bar.dart';

/// Each main tab screen builds its own [Scaffold] and passes the same bottom
/// bar pattern: `bottomNavigationBar: AppBottomNavBar(currentIndex: …)`.
/// Tab switches use `context.go(AppRoutes.*)` from the bar, not push.
class MainTabScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int currentNavIndex;
  final Widget body;
  final Widget? floatingActionButton;
  /// When false, the FAB is not wrapped in the default teal shadow shell (use for custom FABs).
  final bool fabWithDefaultDecoration;
  /// Pinned above [AppBottomNavBar] (e.g. primary CTA) — does not scroll with [body].
  final Widget? aboveBottomNav;
  final List<Widget>? actions;
  final bool showLogout;

  const MainTabScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentNavIndex,
    required this.body,
    this.floatingActionButton,
    this.fabWithDefaultDecoration = true,
    this.aboveBottomNav,
    this.actions,
    this.showLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showLogout: showLogout,
      ),
      body: body,
      floatingActionButton: floatingActionButton != null
          ? fabWithDefaultDecoration
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.fabShadow,
                  ),
                  child: floatingActionButton,
                )
              : floatingActionButton
          : null,
      bottomNavigationBar: aboveBottomNav == null
          ? AppBottomNavBar(currentIndex: currentNavIndex)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                aboveBottomNav!,
                AppBottomNavBar(currentIndex: currentNavIndex),
              ],
            ),
    );
  }
}
