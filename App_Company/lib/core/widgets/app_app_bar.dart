import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../theme/app_theme.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  /// Optional second line under the title (e.g. screen context).
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogout;
  final Widget? leading;
  
  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLogout = true,
    this.leading,
  });
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: subtitle == null
          ? Text(title)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray500,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
      centerTitle: true,
      leading: leading,
      actions: [
        if (showLogout)
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                // Navigate to login after logout
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go(AppRoutes.login);
                });
              }
            },
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<AuthBloc>().add(const LogoutEvent());
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.dangerRed,
                        ),
                        child: const Text('تسجيل الخروج'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (actions != null) ...actions!,
      ],
    );
  }
  
  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 72 : kToolbarHeight);
}
