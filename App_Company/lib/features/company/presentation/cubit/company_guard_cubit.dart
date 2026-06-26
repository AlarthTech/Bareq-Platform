import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/company_entity.dart';
import '../../domain/usecases/get_my_company_usecase.dart';
import '../../../../core/storage/company_session_storage.dart';
import '../../../../core/storage/company_onboarding_storage.dart';

sealed class CompanyGuardState extends Equatable {
  const CompanyGuardState();

  @override
  List<Object?> get props => [];
}

class CompanyGuardInitial extends CompanyGuardState {
  const CompanyGuardInitial();
}

class CompanyGuardLoading extends CompanyGuardState {
  const CompanyGuardLoading();
}

class CompanyGuardNoCompany extends CompanyGuardState {
  const CompanyGuardNoCompany({this.skipped = false});

  final bool skipped;

  @override
  List<Object?> get props => [skipped];
}

class CompanyGuardHasCompany extends CompanyGuardState {
  const CompanyGuardHasCompany(this.companies);

  final List<CompanyEntity> companies;

  @override
  List<Object?> get props => [companies];
}

class CompanyGuardError extends CompanyGuardState {
  const CompanyGuardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CompanyGuardCubit extends Cubit<CompanyGuardState> {
  CompanyGuardCubit({required GetMyCompanyUseCase getMyCompanyUseCase})
      : _getMyCompanyUseCase = getMyCompanyUseCase,
        super(const CompanyGuardInitial());

  final GetMyCompanyUseCase _getMyCompanyUseCase;

  Future<void> refresh(int userId) async {
    emit(const CompanyGuardLoading());
    final result = await _getMyCompanyUseCase(userId);
    await result.fold<Future<void>>(
      (failure) async => emit(CompanyGuardError(failure.message)),
      (companies) async {
        if (companies.isEmpty) {
          await CompanySessionStorage.clear();
          final skipped = await CompanyOnboardingStorage.readSkipped();
          emit(CompanyGuardNoCompany(skipped: skipped));
        } else {
          await CompanyOnboardingStorage.clearSkipped();
          await CompanySessionStorage.savePrimaryCompanyId(companies.first.id);
          emit(CompanyGuardHasCompany(companies));
        }
      },
    );
  }

  Future<void> skipForNow() async {
    await CompanyOnboardingStorage.setSkipped(true);
    emit(const CompanyGuardNoCompany(skipped: true));
  }

  Future<void> markCompanyCreated(CompanyEntity company) async {
    await CompanyOnboardingStorage.clearSkipped();
    await CompanySessionStorage.savePrimaryCompanyId(company.id);
    emit(CompanyGuardHasCompany([company]));
  }

  void reset() {
    emit(const CompanyGuardInitial());
  }
}
