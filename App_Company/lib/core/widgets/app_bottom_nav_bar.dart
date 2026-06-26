import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../theme/app_theme.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case AppRoutes.navDashboard:
        context.go(AppRoutes.dashboard);
        break;
      case AppRoutes.navBookings:
        context.go(AppRoutes.bookings);
        break;
      case AppRoutes.navWorkers:
        context.go(AppRoutes.workers);
        break;
      case AppRoutes.navWorkTypes:
        context.go(AppRoutes.workTypes);
        break;
      case AppRoutes.navProfile:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarTheme.of(context).copyWith(
        indicatorColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppTheme.gray500, size: 24),
            selectedIcon: Icon(Icons.dashboard_rounded, size: 24, color: AppTheme.primaryTeal),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined, color: AppTheme.gray500, size: 24),
            selectedIcon: Icon(Icons.calendar_today_rounded, size: 24, color: AppTheme.primaryTeal),
            label: 'الحجوزات',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppTheme.gray500, size: 24),
            selectedIcon: Icon(Icons.people_rounded, size: 24, color: AppTheme.primaryTeal),
            label: 'العاملات',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined, color: AppTheme.gray500, size: 24),
            selectedIcon: Icon(Icons.schedule_rounded, size: 24, color: AppTheme.primaryTeal),
            label: 'الخدمات',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppTheme.gray500, size: 24),
            selectedIcon: Icon(Icons.person_rounded, size: 24, color: AppTheme.primaryTeal),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
