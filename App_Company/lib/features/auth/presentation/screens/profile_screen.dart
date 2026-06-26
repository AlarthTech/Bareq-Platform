import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/main_tab_scaffold.dart';
import '../../../../core/widgets/saas/saas_card.dart';
import '../../../../core/widgets/saas/saas_section_group.dart';
import '../bloc/account_settings_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

enum _ProfileSection { company, security, support }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ProfileSection? _expandedSection;

  @override
  void initState() {
    super.initState();
    _syncFromAuth();
  }

  void _syncFromAuth() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _nameController.text = auth.user.fullName;
      _emailController.text = auth.user.email ?? '';
      _phoneController.text = auth.user.phone;
    }
  }

  void _toggleSection(_ProfileSection section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }

    return BlocConsumer<AccountSettingsCubit, AccountSettingsState>(
      listener: (context, state) {
        if (state is AccountSettingsFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
          context.read<AccountSettingsCubit>().resetStatus();
        } else if (state is AccountSettingsSuccess) {
          if (state.updatedUser != null) {
            context.read<AuthBloc>().add(UserProfileUpdatedEvent(state.updatedUser!));
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          if (state.updatedUser != null) {
            _nameController.text = state.updatedUser!.fullName;
            _emailController.text = state.updatedUser!.email ?? '';
            _phoneController.text = state.updatedUser!.phone;
          }
          if (state.message.contains('كلمة المرور')) {
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          }
          context.read<AccountSettingsCubit>().resetStatus();
        }
      },
      builder: (context, state) {
        final loading = state is AccountSettingsLoading;

        return MainTabScaffold(
          title: 'حسابي',
          subtitle: 'إعدادات الشركة والحساب',
          currentNavIndex: AppRoutes.navProfile,
          showLogout: false,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _ProfileHeaderCompact(
                userName: auth.user.fullName,
                phone: auth.user.phone,
              ),
              const SizedBox(height: 20),
              SaasSectionGroup(
                icon: Icons.business_outlined,
                title: 'الشركة',
                subtitle: 'إدارة الشركات والملف التجاري',
                isExpanded: _expandedSection == _ProfileSection.company,
                onTap: () => _toggleSection(_ProfileSection.company),
                child: Column(
                  children: [
                    _ProfileLinkTile(
                      icon: Icons.business_center_outlined,
                      title: 'إدارة الشركات',
                      subtitle: 'عرض وتعديل شركاتك',
                      onTap: () => context.push(AppRoutes.companies),
                    ),
                    _ProfileLinkTile(
                      icon: Icons.add_business_outlined,
                      title: 'إضافة شركة جديدة',
                      subtitle: 'إنشاء شركة إضافية',
                      onTap: () => context.push(AppRoutes.addCompany),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SaasSectionGroup(
                icon: Icons.shield_outlined,
                title: 'الأمان',
                subtitle: 'البيانات الشخصية وكلمة المرور',
                isExpanded: _expandedSection == _ProfileSection.security,
                onTap: () => _toggleSection(_ProfileSection.security),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: loading
                          ? null
                          : () {
                              context.read<AccountSettingsCubit>().changePersonalInfo(
                                    fullName: _nameController.text.trim(),
                                    email: _emailController.text.trim().isEmpty
                                        ? null
                                        : _emailController.text.trim(),
                                    currentUser: auth.user,
                                  );
                            },
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('حفظ البيانات'),
                    ),
                    const Divider(height: 28),
                    TextField(
                      controller: _phoneController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: loading
                          ? null
                          : () {
                              context.read<AccountSettingsCubit>().changePhone(
                                    phoneNumber: _phoneController.text.trim(),
                                    currentUser: auth.user,
                                  );
                            },
                      child: const Text('تحديث رقم الهاتف'),
                    ),
                    const Divider(height: 28),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: loading
                          ? null
                          : () {
                              final current = _currentPasswordController.text;
                              final next = _newPasswordController.text;
                              final confirm = _confirmPasswordController.text;
                              if (current.isEmpty || next.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى تعبئة حقول كلمة المرور'),
                                  ),
                                );
                                return;
                              }
                              if (next != confirm) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('كلمة المرور الجديدة غير متطابقة'),
                                  ),
                                );
                                return;
                              }
                              context.read<AccountSettingsCubit>().changePassword(
                                    currentPassword: current,
                                    newPassword: next,
                                  );
                            },
                      child: const Text('تغيير كلمة المرور'),
                    ),
                    const Divider(height: 28),
                    OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () => context.push(AppRoutes.deleteAccount),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('حذف الحساب'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerRed,
                        side: const BorderSide(color: AppTheme.dangerRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SaasSectionGroup(
                icon: Icons.help_outline,
                title: 'الدعم',
                subtitle: 'تواصل مع فريق بريق',
                isExpanded: _expandedSection == _ProfileSection.support,
                onTap: () => _toggleSection(_ProfileSection.support),
                child: Column(
                  children: [
                    _ProfileLinkTile(
                      icon: Icons.support_agent_outlined,
                      title: 'support@albareq.ly',
                      subtitle: 'الدعم الفني',
                      onTap: () => launchUrl(Uri.parse('mailto:support@albareq.ly')),
                    ),
                    _ProfileLinkTile(
                      icon: Icons.mail_outline,
                      title: 'info@albareq.ly',
                      subtitle: 'معلومات عامة',
                      onTap: () => launchUrl(Uri.parse('mailto:info@albareq.ly')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const LogoutEvent());
                  context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeaderCompact extends StatelessWidget {
  const _ProfileHeaderCompact({
    required this.userName,
    required this.phone,
  });

  final String userName;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return SaasCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
            child: Text(
              userName.isNotEmpty ? userName.characters.first : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLinkTile extends StatelessWidget {
  const _ProfileLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.chevron_left, color: AppTheme.gray400, size: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: AppTheme.primaryTeal, size: 22),
          ],
        ),
      ),
    );
  }
}
