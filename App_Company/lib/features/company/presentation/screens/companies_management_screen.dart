import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/forgot_password_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/company_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';
import '../models/edit_company_route_extra.dart';

class CompaniesManagementScreen extends StatefulWidget {
  const CompaniesManagementScreen({super.key});

  @override
  State<CompaniesManagementScreen> createState() =>
      _CompaniesManagementScreenState();
}

class _CompaniesManagementScreenState extends State<CompaniesManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  void _loadCompanies() {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(auth.user.id));
    }
  }

  Future<void> _openEdit(CompanyEntity company) async {
    await context.push<void>(
      AppRoutes.editCompany(company.id),
      extra: EditCompanyRouteExtra(
        company: company,
        companyBloc: context.read<CompanyBloc>(),
      ),
    );
    if (!mounted) return;
    _loadCompanies();
  }

  void _setActive(CompanyEntity company) {
    context.read<CompanyBloc>().add(SelectActiveCompanyEvent(company.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تعيين "${company.name}" كشركة نشطة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        foregroundColor: ForgotPasswordConstants.tealDark,
        title: const Text('إدارة الشركات'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addCompany),
        backgroundColor: AppTheme.primaryTeal,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('شركة جديدة'),
      ),
      body: BlocConsumer<CompanyBloc, CompanyState>(
        listener: (context, state) {
          if (state is CompanyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.dangerRed,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CompanyInitial || state is CompanyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CompanyLoaded) {
            if (state.companies.isEmpty) {
              return _EmptyCompanies(onAdd: () => context.push(AppRoutes.addCompany));
            }

            final activeId = state.selectedCompanyId ?? state.activeCompanyId;

            return RefreshIndicator(
              onRefresh: () async => _loadCompanies(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: state.companies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final company = state.companies[index];
                  final isActive = company.id == activeId;
                  return _CompanyCard(
                    company: company,
                    isActive: isActive,
                    onEdit: () => _openEdit(company),
                    onSetActive: isActive ? null : () => _setActive(company),
                  );
                },
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('تعذّر تحميل الشركات'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _loadCompanies, child: const Text('إعادة المحاولة')),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.company,
    required this.isActive,
    required this.onEdit,
    this.onSetActive,
  });

  final CompanyEntity company;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback? onSetActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryTeal.withValues(alpha: 0.5)
                  : AppTheme.gray200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (company.cityName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            company.cityName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gray500,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'نشطة',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.phone_outlined,
                    label: company.phone,
                  ),
                  if (company.email != null && company.email!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.email_outlined,
                      label: company.email!,
                    ),
                  _InfoChip(
                    icon: company.isVerified
                        ? Icons.verified_outlined
                        : Icons.hourglass_top,
                    label: company.isVerified ? 'موثّقة' : 'بانتظار الموافقة',
                    color: company.isVerified ? AppTheme.successGreen : Colors.amber.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل'),
                    ),
                  ),
                  if (onSetActive != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onSetActive,
                        child: const Text('تعيين كنشطة'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.gray500),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? AppTheme.gray700,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCompanies extends StatelessWidget {
  const _EmptyCompanies({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: AppTheme.gray400),
            const SizedBox(height: 16),
            Text(
              'لا توجد شركات مسجّلة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف شركتك الأولى للبدء',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('إضافة شركة'),
            ),
          ],
        ),
      ),
    );
  }
}
