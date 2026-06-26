import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_top_bar.dart';
import '../../../../core/widgets/common/bareq_nav_chevron.dart';
import '../../../../core/widgets/common/bottom_nav_bar.dart';
import '../widgets/about/about_hero_logo_chip.dart';
import '../widgets/profile_hero_section.dart';
import '../widgets/profile_wallet_balance_card.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/usecases/clear_user_usecase.dart';

/// Profile Screen with Settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LanguageProvider _languageProvider = LanguageProvider.instance;
  final _heroKey = GlobalKey<ProfileHeroSectionState>();

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    
    return ListenableBuilder(
      listenable: _languageProvider,
      builder: (context, _) {
        return Scaffold(
          appBar: AppTopBar(
            title: l10n?.translate('settings') ?? AppStrings.settings,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeroSection(key: _heroKey)
                    .animate()
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
                const ProfileWalletBalanceCard()
                    .animate(delay: 50.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
                // Language Switch Card
                _buildSettingsCard(
                  context,
                  icon: Icons.language,
                  title: l10n?.translate('changeLanguage') ?? 'Change Language',
                  subtitle: _languageProvider.isArabic
                      ? (l10n?.translate('arabic') ?? 'Arabic')
                      : (l10n?.translate('english') ?? 'English'),
                  trailing: Switch(
                    value: _languageProvider.isArabic,
                    onChanged: (value) {
                      _languageProvider.toggleLanguage();
                      setState(() {});
                    },
                    activeColor: AppColors.primary,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                
                // Account Section
                Text(
                  l10n?.translate('account') ?? 'Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500, // Medium for section header
                      ),
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                
                // Account Actions
                _buildSettingsCard(
                  context,
                  icon: Icons.person_outline,
                  title: l10n?.translate('editProfile') ?? 'Edit Profile',
                  onTap: () async {
                    await context.push(AppStrings.routeEditProfile);
                    _heroKey.currentState?.reload();
                  },
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  icon: Icons.place_outlined,
                  title: l10n?.translate('savedLocations') ?? 'Saved locations',
                  onTap: () => context.push(AppStrings.routeSavedLocations),
                )
                    .animate(delay: 175.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n?.translate('wallet') ?? 'المحفظة',
                  onTap: () => context.push(AppStrings.routeWallet),
                )
                    .animate(delay: 185.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                
                _buildSettingsCard(
                  context,
                  icon: Icons.notifications_outlined,
                  title: l10n?.translate('notifications') ?? 'Notifications',
                  subtitle:
                      l10n?.translate('notificationsComingSoonSubtitle') ??
                      'Coming soon',
                  onTap: () => context.push(AppStrings.routeNotificationsSettings),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                
                _buildSettingsCard(
                  context,
                  icon: Icons.lock_outline,
                  title: l10n?.translate('privacyAndSecurity') ?? 'Privacy & Security',
                  onTap: () => context.push(AppStrings.routePrivacySecurity),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  icon: Icons.list_alt,
                  title: l10n?.translate('myReports') ?? 'My reports',
                  onTap: () => context.push(AppStrings.routeMyReports),
                )
                    .animate(delay: 275.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  context,
                  icon: Icons.report_problem_outlined,
                  title:
                      l10n?.translate('myBookingReports') ?? 'بلاغات الحجوزات',
                  onTap: () => context.push(AppStrings.routeMyBookingReports),
                )
                    .animate(delay: 280.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),

                // Legal Section
                Text(
                  l10n?.translate('legal') ?? 'Legal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                )
                    .animate(delay: 275.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),

                _buildSettingsCard(
                  context,
                  icon: Icons.gavel_outlined,
                  title: l10n?.translate('termsAndConditions') ??
                      'Terms & Conditions',
                  onTap: () => context.push(AppStrings.routeTermsConditions),
                )
                    .animate(delay: 285.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),

                _buildSettingsCard(
                  context,
                  icon: Icons.policy_outlined,
                  title: l10n?.translate('privacyPolicy') ?? 'Privacy Policy',
                  onTap: () => context.push(AppStrings.routePrivacyPolicy),
                )
                    .animate(delay: 295.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),

                _buildSettingsCard(
                  context,
                  icon: Icons.mail_outline,
                  title: l10n?.translate('contactUs') ?? 'Contact us',
                  onTap: () => context.push(AppStrings.routeHelpSupport),
                )
                    .animate(delay: 305.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                
                // Support Section
                Text(
                  l10n?.translate('support') ?? 'Support',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500, // Medium for section header
                      ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                
                _buildSettingsCard(
                  context,
                  icon: Icons.help_outline,
                  title: l10n?.translate('helpAndSupport') ?? 'Help & Support',
                  onTap: () => context.push(AppStrings.routeHelpSupport),
                )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                
                _buildSettingsCard(
                  context,
                  icon: Icons.info_outline,
                  title: l10n?.translate('about') ?? 'About',
                  leadingHero: const AboutHeroLogoChip(),
                  onTap: () => context.push(AppStrings.routeAboutBareq),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 24),
                
                // Logout
                _buildSettingsCard(
                  context,
                  icon: Icons.logout,
                  title: l10n?.translate('logout') ?? 'Logout',
                  iconColor: AppColors.error,
                  titleColor: AppColors.error,
                  onTap: () => _showLogoutDialog(context),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
        );
      },
    );
  }
  
  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? leadingHero,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveTitleColor = titleColor ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            leadingHero ??
                Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 24,
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: effectiveTitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null) const BareqNavChevron(),
          ],
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutDialog(BuildContext context) async {
    final l10n = L10n.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n?.translate('logoutConfirm') ?? 'Are you sure you want to logout?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: Text(
            l10n?.translate('logoutConfirmMessage') ??
                'You will need to sign in again to access your account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n?.translate('cancel') ?? 'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n?.translate('logout') ?? 'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await _performLogout(context);
    }
  }

  /// Perform logout: clear session data and navigate to login
  Future<void> _performLogout(BuildContext context) async {
    try {
      await disconnectCustomerNotifications();
      final clearUserUseCase = sl<ClearUserUseCase>();
      await clearUserUseCase();
      
      // Navigate to login screen and clear navigation stack
      if (context.mounted) {
        context.go(AppStrings.routeLogin);
      }
    } catch (e) {
      // If logout fails, still navigate to login
      if (context.mounted) {
        context.go(AppStrings.routeLogin);
      }
    }
  }
}

