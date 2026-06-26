import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/company_entity.dart';

class OnboardingSuccessScreen extends StatelessWidget {
  const OnboardingSuccessScreen({
    super.key,
    required this.company,
    this.uploadFailed = false,
    this.onRetryUpload,
    this.fromAddCompany = false,
  });

  final CompanyEntity company;
  final bool uploadFailed;
  final VoidCallback? onRetryUpload;
  final bool fromAddCompany;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: fromAddCompany,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  decoration: BoxDecoration(
                    color: ForgotPasswordConstants.tealPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_outlined,
                    size: 64,
                    color: ForgotPasswordConstants.tealPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                Text(
                  'تم إنشاء شركتك بنجاح',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ForgotPasswordConstants.tealDark,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  company.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'تم إنشاء شركتك بنجاح. سيتم مراجعتها من قبل الإدارة '
                  'قبل ظهورها للعملاء.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.gray600,
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (!company.isVerified) ...[
                  const SizedBox(height: AppTheme.spacing16),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top, color: Colors.amber.shade800),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: Text(
                            'حالة الشركة: بانتظار موافقة الإدارة',
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (uploadFailed) ...[
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    'تعذّر رفع السجل التجاري. يمكنك المحاولة مرة أخرى أو المتابعة.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.dangerRed,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  if (onRetryUpload != null)
                    OutlinedButton(
                      onPressed: onRetryUpload,
                      child: const Text('إعادة رفع السجل التجاري'),
                    ),
                ],
                const Spacer(),
                AppButton(
                  text: fromAddCompany ? 'تم' : 'الانتقال إلى لوحة التحكم',
                  onPressed: () {
                    if (fromAddCompany) {
                      context.pop();
                      context.pop();
                    } else {
                      context.go(AppRoutes.dashboard);
                    }
                  },
                  isFullWidth: true,
                  icon: fromAddCompany ? Icons.check_rounded : Icons.dashboard_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
