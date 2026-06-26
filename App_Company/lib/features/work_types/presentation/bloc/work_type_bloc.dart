import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_work_types_usecase.dart';
import '../../domain/usecases/create_work_type_usecase.dart';
import '../../domain/usecases/update_work_type_usecase.dart';
import '../../domain/usecases/delete_work_type_usecase.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import 'work_type_event.dart';
import 'work_type_state.dart';

class WorkTypeBloc extends Bloc<WorkTypeEvent, WorkTypeState> {
  final GetWorkTypesUseCase getWorkTypesUseCase;
  final CreateWorkTypeUseCase createWorkTypeUseCase;
  final UpdateWorkTypeUseCase updateWorkTypeUseCase;
  final DeleteWorkTypeUseCase deleteWorkTypeUseCase;

  int? _lastCompanyId;
  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;

  WorkTypeBloc({
    required this.getWorkTypesUseCase,
    required this.createWorkTypeUseCase,
    required this.updateWorkTypeUseCase,
    required this.deleteWorkTypeUseCase,
  }) : super(const WorkTypeInitial()) {
    on<GetWorkTypesEvent>(_onGetWorkTypes);
    on<LoadMoreWorkTypesEvent>(_onLoadMoreWorkTypes);
    on<CreateWorkTypeEvent>(_onCreateWorkType);
    on<UpdateWorkTypeEvent>(_onUpdateWorkType);
    on<DeleteWorkTypeEvent>(_onDeleteWorkType);
  }

  Future<void> _onGetWorkTypes(
    GetWorkTypesEvent event,
    Emitter<WorkTypeState> emit,
  ) async {
    _lastCompanyId = event.companyId;
    _currentPage = 1;
    emit(const WorkTypeLoading());

    final result = await getWorkTypesUseCase(
      GetWorkTypesParams(companyId: event.companyId),
    );

    result.fold(
      (failure) => emit(WorkTypeError(failure.message)),
      (page) {
        _hasNextPage = page.hasNextPage;
        _currentPage = page.page;
        emit(
          WorkTypesLoaded(
            workTypes: page.items,
            hasNextPage: page.hasNextPage,
            totalCount: page.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreWorkTypes(
    LoadMoreWorkTypesEvent event,
    Emitter<WorkTypeState> emit,
  ) async {
    if (!_hasNextPage || _isLoadingMore) return;
    final current = state;
    if (current is! WorkTypesLoaded) return;

    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));

    final result = await getWorkTypesUseCase(
      GetWorkTypesParams(
        companyId: event.companyId,
        pagination: PaginationParams(page: _currentPage + 1),
      ),
    );

    _isLoadingMore = false;

    result.fold(
      (failure) => emit(WorkTypeError(failure.message)),
      (page) {
        _hasNextPage = page.hasNextPage;
        _currentPage = page.page;
        emit(
          WorkTypesLoaded(
            workTypes: [...current.workTypes, ...page.items],
            hasNextPage: page.hasNextPage,
            totalCount: page.totalCount,
          ),
        );
      },
    );
  }

  Future<void> _onCreateWorkType(
    CreateWorkTypeEvent event,
    Emitter<WorkTypeState> emit,
  ) async {
    final result = await createWorkTypeUseCase(
      CreateWorkTypeParams(
        name: event.name,
        companyId: event.companyId,
        isMonthly: event.isMonthly,
        price: event.price,
        startTime: event.startTime,
        endTime: event.endTime,
        isOvernight: event.isOvernight,
      ),
    );

    result.fold(
      (failure) => emit(WorkTypeError(failure.message)),
      (workType) => emit(WorkTypeCreated(workType)),
    );
  }

  Future<void> _onUpdateWorkType(
    UpdateWorkTypeEvent event,
    Emitter<WorkTypeState> emit,
  ) async {
    emit(const WorkTypeLoading());

    final result = await updateWorkTypeUseCase(
      UpdateWorkTypeParams(
        workTypeId: event.workTypeId,
        name: event.name,
        isMonthly: event.isMonthly,
        price: event.price,
        isActive: event.isActive,
        startTime: event.startTime,
        endTime: event.endTime,
        isOvernight: event.isOvernight,
      ),
    );

    result.fold(
      (failure) => emit(WorkTypeError(failure.message)),
      (_) {
        emit(WorkTypeUpdated(event.workTypeId));
        final companyId = _lastCompanyId;
        if (companyId != null) {
          add(GetWorkTypesEvent(companyId));
        }
      },
    );
  }

  Future<void> _onDeleteWorkType(
    DeleteWorkTypeEvent event,
    Emitter<WorkTypeState> emit,
  ) async {
    final result = await deleteWorkTypeUseCase(event.workTypeId);

    result.fold(
      (failure) => emit(WorkTypeError(failure.message)),
      (_) {
        emit(WorkTypeDeleted(event.workTypeId));
        final companyId = _lastCompanyId;
        if (companyId != null) {
          add(GetWorkTypesEvent(companyId));
        }
      },
    );
  }
}
