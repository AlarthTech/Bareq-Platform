import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../localization/l10n_helper.dart';

/// Bottom navigation bar for main app navigation
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppStrings.routeHome);
        break;
      case 1:
        context.go(AppStrings.routeCompanies);
        break;
      case 2:
        context.go(AppStrings.routeBookings);
        break;
      case 3:
        context.go(AppStrings.routeFavorites);
        break;
      case 4:
        context.go(AppStrings.routeProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.5), // Stronger contrast
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700, // Bolder active label
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary.withOpacity(0.5), // Lighter opacity for inactive
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined, size: 24),
            activeIcon: const Icon(Icons.home, size: 26), // Increased by ~8%
            label: l10n?.translate('navHome') ?? AppStrings.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.business_outlined, size: 24),
            activeIcon: const Icon(Icons.business, size: 26), // Increased by ~8%
            label: l10n?.translate('navCompanies') ?? AppStrings.navCompanies,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined, size: 24),
            activeIcon: const Icon(Icons.calendar_today, size: 26), // Increased by ~8%
            label: l10n?.translate('navBookings') ?? AppStrings.navBookings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline, size: 24),
            activeIcon: const Icon(Icons.favorite, size: 26), // Increased by ~8%
            label: l10n?.translate('navFavorites') ?? AppStrings.navFavorites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline, size: 24),
            activeIcon: const Icon(Icons.person, size: 26), // Increased by ~8%
            label: l10n?.translate('navProfile') ?? AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}

