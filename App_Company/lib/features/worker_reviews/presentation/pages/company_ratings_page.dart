import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_shimmer_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';
import '../state/company_ratings_cubit.dart';
import '../state/company_ratings_state.dart';
import '../widgets/company_rating_header.dart';
import '../widgets/review_list_item.dart';
import '../widgets/worker_rating_tile.dart';

class CompanyRatingsPage extends StatefulWidget {
  const CompanyRatingsPage({super.key});

  @override
  State<CompanyRatingsPage> createState() => _CompanyRatingsPageState();
}

class _CompanyRatingsPageState extends State<CompanyRatingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(authState.user.id));
    }
    final companyState = context.read<CompanyBloc>().state;
    if (companyState is CompanyLoaded && companyState.activeCompanyId != null) {
      context.read<CompanyRatingsCubit>().load(companyState.activeCompanyId!);
    }
  }

  Future<void> _refresh() async {
    final companyState = context.read<CompanyBloc>().state;
    if (companyState is CompanyLoaded && companyState.activeCompanyId != null) {
      await context
          .read<CompanyRatingsCubit>()
          .refresh(companyState.activeCompanyId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listenWhen: (prev, curr) =>
          curr is CompanyLoaded &&
          curr.activeCompanyId != null &&
          (prev is! CompanyLoaded ||
              prev.activeCompanyId != curr.activeCompanyId),
      listener: (context, state) {
        if (state is CompanyLoaded && state.activeCompanyId != null) {
          context.read<CompanyRatingsCubit>().load(state.activeCompanyId!);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceBackground,
        appBar: AppAppBar(
          title: 'التقييمات والمراجعات',
          showLogout: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<CompanyRatingsCubit, CompanyRatingsState>(
          builder: (context, state) {
            if (state is CompanyRatingsLoading) {
              return ListView(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                children: [
                  LoadingShimmerWidget(
                    height: 140,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    4,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LoadingShimmerWidget(
                        height: 72,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is CompanyRatingsError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: _load,
              );
            }

            if (state is! CompanyRatingsLoaded) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppTheme.primaryTeal,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacing16),
                children: [
                  CompanyRatingHeader(summary: state.companySummary),
                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    'تقييمات العاملات',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gray800,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  if (state.rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('لا توجد عاملات مسجّلة')),
                    )
                  else
                    ...state.rows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                        child: WorkerRatingTile(
                          row: row,
                          onTap: () => openWorkerReviews(
                            context,
                            workerId: row.worker.id,
                            workerName: row.worker.fullName,
                            profileImage: row.worker.profileImage,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
