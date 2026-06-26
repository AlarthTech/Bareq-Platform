import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/usecases/get_my_company_usecase.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_state.dart';
import '../cubit/company_guard_cubit.dart';
import 'edit_company_screen.dart';

class EditCompanyEntryScreen extends StatefulWidget {
  const EditCompanyEntryScreen({
    super.key,
    required this.companyId,
    this.initialCompany,
    this.companyBloc,
  });

  final int companyId;
  final CompanyEntity? initialCompany;
  final CompanyBloc? companyBloc;

  @override
  State<EditCompanyEntryScreen> createState() => _EditCompanyEntryScreenState();
}

class _EditCompanyEntryScreenState extends State<EditCompanyEntryScreen> {
  CompanyEntity? _company;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _company = widget.initialCompany;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveCompany());
  }

  CompanyEntity? _findInBloc() {
    final bloc = widget.companyBloc;
    if (bloc == null) return null;
    final state = bloc.state;
    if (state is! CompanyLoaded) return null;
    for (final company in state.companies) {
      if (company.id == widget.companyId) return company;
    }
    return null;
  }

  CompanyEntity? _findInGuard() {
    final guard = context.read<CompanyGuardCubit>().state;
    if (guard is! CompanyGuardHasCompany) return null;
    for (final company in guard.companies) {
      if (company.id == widget.companyId) return company;
    }
    return null;
  }

  Future<void> _resolveCompany() async {
    if (_company != null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final fromBloc = _findInBloc();
    if (fromBloc != null) {
      if (mounted) {
        setState(() {
          _company = fromBloc;
          _loading = false;
          _error = null;
        });
      }
      return;
    }

    final fromGuard = _findInGuard();
    if (fromGuard != null) {
      if (mounted) {
        setState(() {
          _company = fromGuard;
          _loading = false;
          _error = null;
        });
      }
      return;
    }

    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'بيانات الشركة غير متوفرة';
        });
      }
      return;
    }

    final result = await getIt<GetMyCompanyUseCase>()(auth.user.id);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (companies) {
        CompanyEntity? found;
        for (final company in companies) {
          if (company.id == widget.companyId) {
            found = company;
            break;
          }
        }
        setState(() {
          _company = found;
          _loading = false;
          _error = found == null ? 'بيانات الشركة غير متوفرة' : null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return BlocListener<CompanyGuardCubit, CompanyGuardState>(
        listenWhen: (previous, current) =>
            _company == null && current is CompanyGuardHasCompany,
        listener: (context, state) {
          if (state is! CompanyGuardHasCompany) return;
          for (final company in state.companies) {
            if (company.id == widget.companyId) {
              setState(() {
                _company = company;
                _loading = false;
                _error = null;
              });
              return;
            }
          }
        },
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_company == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error ?? 'بيانات الشركة غير متوفرة',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _resolveCompany();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return EditCompanyScreen(company: _company!);
  }
}
