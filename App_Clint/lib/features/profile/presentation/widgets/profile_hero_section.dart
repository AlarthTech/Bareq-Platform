import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/l10n_helper.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/get_current_user_usecase.dart';

/// Profile header with full name title, phone, and email.
class ProfileHeroSection extends StatefulWidget {
  const ProfileHeroSection({super.key});

  @override
  ProfileHeroSectionState createState() => ProfileHeroSectionState();
}

class ProfileHeroSectionState extends State<ProfileHeroSection> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final result = await sl<GetCurrentUserUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loading = false;
        _user = null;
      }),
      (user) => setState(() {
        _loading = false;
        _user = user;
      }),
    );
  }

  String _orPlaceholder(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '—';
    }
    return trimmed;
  }

  String _avatarLetter(User user) {
    final name = user.fullName?.trim();
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    final username = user.username.trim();
    if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    if (_loading) {
      return const SizedBox(
        height: 168,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;
    if (user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _heroDecoration(context),
        child: Text(
          l10n?.translate('profileLoadFailed') ??
              'Could not load your profile.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    final displayTitle = user.fullName?.trim().isNotEmpty == true
        ? user.fullName!.trim()
        : user.username.trim().isNotEmpty
            ? user.username.trim()
            : (l10n?.translate('profile') ?? 'Profile');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: _heroDecoration(context),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              _avatarLetter(user),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: l10n?.translate('phoneNumber') ?? 'Phone',
            value: _orPlaceholder(user.phone),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.email_outlined,
            label: l10n?.translate('email') ?? 'Email',
            value: _orPlaceholder(user.email),
          ),
        ],
      ),
    );
  }

  BoxDecoration _heroDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.5),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
