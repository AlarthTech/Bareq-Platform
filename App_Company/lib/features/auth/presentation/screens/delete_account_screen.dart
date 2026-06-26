import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/delete_account_cubit.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _inlinePasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _inlinePasswordError = null);
    context.read<DeleteAccountCubit>().deleteAccount(_passwordController.text);
  }

  Future<void> _showActiveBookingsDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لا يمكن الحذف الآن'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(AppRoutes.bookingsOngoing());
            },
            child: const Text('عرض الحجوزات'),
          ),
        ],
      ),
    );
    if (mounted) {
      context.read<DeleteAccountCubit>().resetStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listener: (context, state) {
        if (state is DeleteAccountSuccess) {
          context.read<AuthBloc>().add(const LogoutEvent());
          context.go(AppRoutes.login);
          return;
        }
        if (state is DeleteAccountPasswordError) {
          setState(() => _inlinePasswordError = state.message);
          context.read<DeleteAccountCubit>().resetStatus();
          return;
        }
        if (state is DeleteAccountActiveBookings) {
          _showActiveBookingsDialog(state.message);
          return;
        }
        if (state is DeleteAccountUnauthorized) {
          context.read<AuthBloc>().add(const LogoutEvent());
          context.go(AppRoutes.login);
          return;
        }
        if (state is DeleteAccountRateLimited) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<DeleteAccountCubit>().resetStatus();
          return;
        }
        if (state is DeleteAccountFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
          context.read<DeleteAccountCubit>().resetStatus();
        }
      },
      builder: (context, state) {
        final loading = state is DeleteAccountLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('حذف الحساب'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.dangerRed.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.dangerRed,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          'سيتم حذف حسابك نهائياً ولن تتمكن من تسجيل الدخول مرة أخرى. '
                          'ستُوقف شركاتك وعمالك عن الظهور في التطبيق.',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: AppTheme.gray800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textAlign: TextAlign.right,
                  enabled: !loading,
                  decoration: InputDecoration(
                    labelText: 'أدخل كلمة المرور للتأكيد',
                    errorText: _inlinePasswordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: loading
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                    ),
                  ),
                  onSubmitted: loading ? null : (_) => _submit(),
                ),
                const SizedBox(height: AppTheme.spacing24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حذف الحساب نهائياً'),
                ),
                const SizedBox(height: AppTheme.spacing12),
                OutlinedButton(
                  onPressed: loading ? null : () => context.pop(),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
