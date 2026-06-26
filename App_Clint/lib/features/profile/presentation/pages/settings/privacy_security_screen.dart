import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/localization/l10n_helper.dart';
import '../../../../../core/widgets/common/app_top_bar.dart';
import '../../../../../core/widgets/common/bareq_nav_chevron.dart';
import '../../../../auth/domain/usecases/delete_account_usecase.dart';
import '../../../../auth/domain/usecases/get_current_user_usecase.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  static const _analyticsKey = 'privacy_share_usage_analytics';
  bool _analytics = false;
  bool _loading = true;
  String? _currentPhone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userRes = await sl<GetCurrentUserUseCase>()();
    if (!mounted) return;
    userRes.fold(
      (_) {},
      (user) => _currentPhone = user?.phone,
    );
    setState(() {
      _analytics = prefs.getBool(_analyticsKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _openChangePhone() async {
    final updated = await context.push<bool>(AppStrings.routeChangePhone);
    if (updated == true && mounted) {
      await _load();
    }
  }

  Future<void> _openChangePassword() async {
    await context.push(AppStrings.routeChangePassword);
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = L10n.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  l10n?.translate('deleteAccount') ?? 'Delete account',
                ),
                content: Text(
                  l10n?.translate('deleteAccountConfirm') ??
                      'This will permanently delete your account and sign you out. This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n?.translate('cancel') ?? 'Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n?.translate('delete') ?? 'Delete'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await sl<DeleteAccountUseCase>()();
    if (!mounted) return;
    Navigator.pop(context);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        context.go(AppStrings.routeLogin);
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(title),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
              : null,
      trailing: const BareqNavChevron(),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('privacyAndSecurity') ?? 'Privacy & Security',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    l10n?.translate('accountSecurity') ?? 'Account security',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        _actionTile(
                          icon: Icons.phone_outlined,
                          title:
                              l10n?.translate('changePhoneNumber') ??
                              'Change phone number',
                          subtitle: _currentPhone,
                          onTap: _openChangePhone,
                        ),
                        const Divider(height: 1, indent: 56),
                        _actionTile(
                          icon: Icons.lock_reset,
                          title:
                              l10n?.translate('changePassword') ??
                              'Change password',
                          subtitle:
                              l10n?.translate('changePasswordHint') ??
                              'Requires your current password',
                          onTap: _openChangePassword,
                        ),
                        const Divider(height: 1, indent: 56),
                        _actionTile(
                          icon: Icons.person_remove_outlined,
                          title:
                              l10n?.translate('deleteAccount') ??
                              'Delete account',
                          subtitle:
                              l10n?.translate('deleteAccountHint') ??
                              'Permanently remove your account',
                          iconColor: AppColors.error,
                          onTap: _confirmDeleteAccount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.translate('privacy') ?? 'Privacy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      l10n?.translate('privacyPolicySummary') ??
                          'Your personal data is stored securely.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        l10n?.translate('usageAnalytics') ??
                            'Usage analytics',
                      ),
                      subtitle: Text(
                        l10n?.translate('usageAnalyticsHint') ??
                            'Help improve Bareq with anonymous usage data',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      value: _analytics,
                      activeColor: AppColors.primary,
                      onChanged: (v) async {
                        setState(() => _analytics = v);
                        final prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool(_analyticsKey, v);
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
