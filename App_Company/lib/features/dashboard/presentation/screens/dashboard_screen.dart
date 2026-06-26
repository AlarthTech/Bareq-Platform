import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/main_tab_scaffold.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';
import '../../../company/presentation/cubit/company_guard_cubit.dart';
import '../../../bookings/presentation/cubit/booking_realtime_cubit.dart';
import '../widgets/dashboard_operational_content.dart';
import '../../../notifications/presentation/widgets/notification_bell_icon.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(authState.user.id));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final companyState = context.read<CompanyBloc>().state;
      if (companyState is CompanyLoaded && companyState.activeCompanyId != null) {
        context.read<DashboardBloc>().add(
              LoadDashboardDataEvent(companyState.activeCompanyId!),
            );
      }
    });
  }

  bool _hasNoCompany(CompanyState companyState, CompanyGuardState guardState) {
    if (guardState is CompanyGuardHasCompany) return false;
    if (companyState is CompanyLoaded && companyState.activeCompanyId != null) {
      return false;
    }
    return true;
  }

  String _greetingName(CompanyState companyState, AuthState authState) {
    if (companyState is CompanyLoaded && companyState.activeCompany != null) {
      return companyState.activeCompany!.name;
    }
    if (authState is AuthAuthenticated) {
      return authState.user.fullName;
    }
    return '…';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingRealtimeCubit, BookingRealtimeState>(
      listenWhen: (prev, curr) =>
          curr.lastEvent != null && prev.lastEvent != curr.lastEvent,
      listener: (context, state) {
        final event = state.lastEvent;
        if (event == null) return;
        context.read<DashboardBloc>().add(
              PatchBookingStatusDashboardEvent(
                bookingId: event.bookingId,
                status: event.status,
              ),
            );
      },
      child: BlocListener<CompanyBloc, CompanyState>(
      listenWhen: (prev, curr) =>
          curr is CompanyLoaded &&
          curr.activeCompanyId != null &&
          (prev is! CompanyLoaded ||
              prev.activeCompanyId != curr.activeCompanyId),
      listener: (context, state) {
        if (state is CompanyLoaded && state.activeCompanyId != null) {
          context.read<DashboardBloc>().add(
                LoadDashboardDataEvent(state.activeCompanyId!),
              );
        }
      },
      child: BlocBuilder<CompanyGuardCubit, CompanyGuardState>(
        builder: (context, guardState) {
          return BlocBuilder<CompanyBloc, CompanyState>(
            builder: (context, companyState) {
              final authState = context.watch<AuthBloc>().state;
              final companyName = _greetingName(companyState, authState);
              final noCompany = _hasNoCompany(companyState, guardState);

              return MainTabScaffold(
                title: 'مرحباً، $companyName',
                subtitle: noCompany ? 'أكمل إعداد حسابك' : 'نظرة عامة اليوم',
                currentNavIndex: AppRoutes.navDashboard,
                actions: noCompany ? null : const [NotificationBellIcon()],
                body: noCompany
                    ? _NoCompanyRequiredAlert(
                        onCreateCompany: () => context.go(AppRoutes.createCompany),
                      )
                    : BlocBuilder<DashboardBloc, DashboardState>(
                        builder: (context, state) {
                          if (state is DashboardLoading) {
                            return const _DashboardSkeleton();
                          }

                          if (state is DashboardError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTheme.spacing24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.dangerRed.withValues(alpha: 0.85)),
                                    const SizedBox(height: AppTheme.spacing16),
                                    Text(
                                      state.message,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.spacing24),
                                    FilledButton(
                                      onPressed: () {
                                        final cs = context.read<CompanyBloc>().state;
                                        if (cs is CompanyLoaded && cs.activeCompanyId != null) {
                                          context.read<DashboardBloc>().add(
                                                LoadDashboardDataEvent(cs.activeCompanyId!),
                                              );
                                        }
                                      },
                                      child: const Text('إعادة المحاولة'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (state is DashboardLoaded) {
                            return DashboardOperationalContent(
                              data: state.data,
                              onBookingReports: () =>
                                  context.push(AppRoutes.companyBookingReports),
                            );
                          }

                          return const Center(child: Text('لا توجد بيانات'));
                        },
                      ),
              );
            },
          );
        },
      ),
    ),
    );
  }
}

class _NoCompanyRequiredAlert extends StatelessWidget {
  const _NoCompanyRequiredAlert({required this.onCreateCompany});

  final VoidCallback onCreateCompany;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: AppTheme.warningAmber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.warningAmber.withValues(alpha: 0.35)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.business_outlined,
                size: 56,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'يجب إنشاء شركة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'لبدء إدارة العاملات والحجوزات، يرجى إنشاء شركتك أولاً.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.gray700,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              FilledButton.icon(
                onPressed: onCreateCompany,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('إنشاء الشركة'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        LoadingShimmerWidget(height: 72, borderRadius: BorderRadius.circular(14)),
        const SizedBox(height: AppTheme.spacing24),
        Row(
          children: [
            Expanded(child: LoadingShimmerWidget(height: 120, borderRadius: BorderRadius.circular(16))),
            const SizedBox(width: 12),
            Expanded(child: LoadingShimmerWidget(height: 120, borderRadius: BorderRadius.circular(16))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: LoadingShimmerWidget(height: 120, borderRadius: BorderRadius.circular(16))),
            const SizedBox(width: 12),
            Expanded(child: LoadingShimmerWidget(height: 120, borderRadius: BorderRadius.circular(16))),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: LoadingShimmerWidget(height: 130, borderRadius: BorderRadius.circular(16))),
            const SizedBox(width: 12),
            Expanded(child: LoadingShimmerWidget(height: 130, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ],
    );
  }
}
