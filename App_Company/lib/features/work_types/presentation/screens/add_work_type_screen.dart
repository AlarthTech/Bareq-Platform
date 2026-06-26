import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/work_type_form_sheet.dart';
import '../bloc/work_type_bloc.dart';
import '../bloc/work_type_event.dart';
import '../bloc/work_type_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../company/presentation/bloc/company_bloc.dart';
import '../../../company/presentation/bloc/company_event.dart';
import '../../../company/presentation/bloc/company_state.dart';

class AddWorkTypeScreen extends StatefulWidget {
  const AddWorkTypeScreen({super.key});

  @override
  State<AddWorkTypeScreen> createState() => _AddWorkTypeScreenState();
}

class _AddWorkTypeScreenState extends State<AddWorkTypeScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyBloc>().add(GetMyCompanyEvent(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppAppBar(
        title: 'إضافة تصنيف',
        subtitle: 'دوام يومي أو شهري',
        showLogout: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(false),
        ),
      ),
      body: BlocListener<WorkTypeBloc, WorkTypeState>(
        listener: (context, state) {
          if (state is WorkTypeError) {
            if (mounted) setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.dangerRed,
              ),
            );
          } else if (state is WorkTypeCreated) {
            if (mounted) setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حفظ التصنيف بنجاح'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
            context.pop(true);
          }
        },
        child: BlocBuilder<CompanyBloc, CompanyState>(
          builder: (context, companyState) {
            if (companyState is! CompanyLoaded || companyState.activeCompanyId == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final companyId = companyState.activeCompanyId!;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacing16,
                AppTheme.spacing8,
                AppTheme.spacing16,
                AppTheme.spacing32,
              ),
              child: WorkTypeFormSheet(
                isSubmitting: _submitting,
                submitLabel: 'حفظ التصنيف',
                onSubmit: ({
                  required name,
                  required isMonthly,
                  required price,
                  startTime,
                  endTime,
                }) {
                  setState(() => _submitting = true);
                  context.read<WorkTypeBloc>().add(
                        CreateWorkTypeEvent(
                          name: name,
                          companyId: companyId,
                          isMonthly: isMonthly,
                          price: price,
                          startTime: startTime,
                          endTime: endTime,
                        ),
                      );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
