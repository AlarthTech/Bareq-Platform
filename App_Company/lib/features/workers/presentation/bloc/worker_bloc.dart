import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/language_entity.dart';
import '../../domain/entities/nationality_entity.dart';
import '../../domain/usecases/get_workers_usecase.dart';
import '../../domain/usecases/create_worker_usecase.dart';
import '../../domain/usecases/get_nationalities_usecase.dart';
import '../../domain/usecases/get_languages_usecase.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import 'worker_event.dart';
import 'worker_state.dart';

class WorkerBloc extends Bloc<WorkerEvent, WorkerState> {
  final GetWorkersUseCase getWorkersUseCase;
  final CreateWorkerUseCase createWorkerUseCase;
  final GetNationalitiesUseCase getNationalitiesUseCase;
  final GetLanguagesUseCase getLanguagesUseCase;

  List<NationalityEntity> _cachedNationalities = const [];
  List<LanguageEntity> _cachedLanguages = const [];

  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;

  WorkerBloc({
    required this.getWorkersUseCase,
    required this.createWorkerUseCase,
    required this.getNationalitiesUseCase,
    required this.getLanguagesUseCase,
  }) : super(const WorkerInitial()) {
    on<GetWorkersEvent>(_onGetWorkers);
    on<LoadMoreWorkersEvent>(_onLoadMoreWorkers);
    on<CreateWorkerEvent>(_onCreateWorker);
    on<LoadWorkerFormLookupsEvent>(_onLoadWorkerFormLookups);
  }

  Future<void> _onGetWorkers(
    GetWorkersEvent event,
    Emitter<WorkerState> emit,
  ) async {
    emit(const WorkerLoading());
    _currentPage = 1;

    final result = await getWorkersUseCase(
      GetWorkersParams(companyId: event.companyId),
    );

    result.fold(
      (failure) => emit(WorkerError(failure.message)),
      (page) {
        _hasNextPage = page.hasNextPage;
        _currentPage = page.page;
        emit(
          WorkersLoaded(
            workers: page.items,
            hasNextPage: page.hasNextPage,
            totalCount: page.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreWorkers(
    LoadMoreWorkersEvent event,
    Emitter<WorkerState> emit,
  ) async {
    if (!_hasNextPage || _isLoadingMore) return;
    final current = state;
    if (current is! WorkersLoaded) return;

    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));

    final result = await getWorkersUseCase(
      GetWorkersParams(
        companyId: event.companyId,
        pagination: PaginationParams(page: _currentPage + 1),
      ),
    );

    _isLoadingMore = false;

    result.fold(
      (failure) => emit(WorkerError(failure.message)),
      (page) {
        _hasNextPage = page.hasNextPage;
        _currentPage = page.page;
        emit(
          WorkersLoaded(
            workers: [...current.workers, ...page.items],
            hasNextPage: page.hasNextPage,
            totalCount: page.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onCreateWorker(
    CreateWorkerEvent event,
    Emitter<WorkerState> emit,
  ) async {
    final result = await createWorkerUseCase(
      CreateWorkerParams(
        companyId: event.companyId,
        fullName: event.fullName,
        nationalityId: event.nationalityId,
        age: event.age,
        experienceYears: event.experienceYears,
        isAvailable: event.isAvailable,
        isActive: event.isActive,
        profileImage: event.profileImage,
        healthCertificate: event.healthCertificate,
        healthCertificateExpiryDate: event.healthCertificateExpiryDate,
        languagesIds: event.languagesIds,
      ),
    );

    result.fold(
      (failure) {
        emit(WorkerError(failure.message));
        if (_cachedNationalities.isNotEmpty || _cachedLanguages.isNotEmpty) {
          emit(
            WorkerLookupsLoaded(
              nationalities: _cachedNationalities,
              languages: _cachedLanguages,
            ),
          );
        }
      },
      (worker) => emit(WorkerCreated(worker)),
    );
  }

  Future<void> _onLoadWorkerFormLookups(
    LoadWorkerFormLookupsEvent event,
    Emitter<WorkerState> emit,
  ) async {
    emit(const WorkerLookupsLoading());

    final natResult = await getNationalitiesUseCase();
    if (natResult.isLeft()) {
      emit(WorkerError(natResult.fold((l) => l.message, (r) => '')));
      return;
    }
    final nationalities = natResult.fold((l) => <NationalityEntity>[], (r) => r);

    final langResult = await getLanguagesUseCase();
    if (langResult.isLeft()) {
      emit(WorkerError(langResult.fold((l) => l.message, (r) => '')));
      return;
    }
    final languages = langResult.fold((l) => <LanguageEntity>[], (r) => r);

    _cachedNationalities = nationalities;
    _cachedLanguages = languages;
    emit(
      WorkerLookupsLoaded(
        nationalities: nationalities,
        languages: languages,
      ),
    );
  }
}
