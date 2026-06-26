import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_company_workers_with_ratings.dart';
import 'company_ratings_state.dart';

class CompanyRatingsCubit extends Cubit<CompanyRatingsState> {
  CompanyRatingsCubit({
    required GetCompanyWorkersWithRatingsUseCase getCompanyWorkersWithRatingsUseCase,
  })  : _getCompanyWorkersWithRatingsUseCase =
            getCompanyWorkersWithRatingsUseCase,
        super(const CompanyRatingsInitial());

  final GetCompanyWorkersWithRatingsUseCase _getCompanyWorkersWithRatingsUseCase;

  Future<void> load(int companyId) async {
    if (state is! CompanyRatingsLoaded) {
      emit(const CompanyRatingsLoading());
    } else {
      emit((state as CompanyRatingsLoaded).copyWith(isRefreshing: true));
    }

    final result = await _getCompanyWorkersWithRatingsUseCase(companyId);
    result.fold(
      (failure) => emit(CompanyRatingsError(failure.message)),
      (data) => emit(CompanyRatingsLoaded(data: data)),
    );
  }

  Future<void> refresh(int companyId) => load(companyId);
}
