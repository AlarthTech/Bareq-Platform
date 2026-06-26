import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/localization/l10n_helper.dart';
import '../../../../../core/widgets/common/app_top_bar.dart';
import '../../../../../core/utils/failure_ui.dart';
import '../../../../auth/domain/usecases/change_password_usecase.dart';
import '../../../../auth/domain/usecases/clear_user_usecase.dart';
import '../../../../../core/constants/app_strings.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final result = await sl<ChangePasswordUseCase>()(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    final l10n = L10n.of(context);
    result.fold(
      (failure) {
        if (failureRequiresLogout(failure)) {
          sl<ClearUserUseCase>().call().then((_) {
            if (mounted) context.go(AppStrings.routeLogin);
          });
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage(context, failure)),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.translate('passwordUpdated') ??
                  'Password updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      },
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: onToggleObscure,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      appBar: AppTopBar(
        title: l10n?.translate('changePassword') ?? 'Change password',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n?.translate('changePasswordFormHint') ??
                    'Enter your current password, then choose a new password of at least 6 characters.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _currentController,
                obscureText: _obscureCurrent,
                enabled: !_saving,
                decoration: _fieldDecoration(
                  label:
                      l10n?.translate('currentPassword') ?? 'Current password',
                  obscure: _obscureCurrent,
                  onToggleObscure:
                      () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? l10n?.translate('passwordRequired') ?? 'Required'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newController,
                obscureText: _obscureNew,
                enabled: !_saving,
                decoration: _fieldDecoration(
                  label: l10n?.translate('newPassword') ?? 'New password',
                  obscure: _obscureNew,
                  onToggleObscure:
                      () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return l10n?.translate('passwordTooShort') ??
                        'At least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                enabled: !_saving,
                decoration: _fieldDecoration(
                  label:
                      l10n?.translate('confirmPassword') ?? 'Confirm password',
                  obscure: _obscureConfirm,
                  onToggleObscure:
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v != _newController.text) {
                    return l10n?.translate('passwordsDoNotMatch') ??
                        'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child:
                    _saving
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(l10n?.translate('save') ?? 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
