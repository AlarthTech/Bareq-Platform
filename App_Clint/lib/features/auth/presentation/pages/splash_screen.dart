import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/auth/auth_session_notifier.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/usecases/check_authentication_usecase.dart';

/// Splash Screen
/// First screen shown when app launches
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Simulate app initialization
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is authenticated
    try {
      final checkAuthUseCase = sl<CheckAuthenticationUseCase>();
      final result = await checkAuthUseCase();

      result.fold(
        (_) {
          // Error checking auth, navigate to login
          if (mounted) {
            context.go(AppStrings.routeLogin);
          }
        },
        (isAuthenticated) {
          if (mounted) {
            if (isAuthenticated) {
              context.go(sl<AuthSessionNotifier>().postAuthHomeRoute);
            } else {
              context.go(AppStrings.routeLogin);
            }
          }
        },
      );
    } catch (e) {
      // If check fails, navigate to login
      if (mounted) {
        context.go(AppStrings.routeLogin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/bareq_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}






