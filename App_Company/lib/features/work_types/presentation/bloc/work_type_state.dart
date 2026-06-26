import 'package:equatable/equatable.dart';
import '../../domain/entities/work_type_entity.dart';

abstract class WorkTypeState extends Equatable {
  const WorkTypeState();

  @override
  List<Object?> get props => [];
}

class WorkTypeInitial extends WorkTypeState {
  const WorkTypeInitial();
}

class WorkTypeLoading extends WorkTypeState {
  const WorkTypeLoading();
}

class WorkTypesLoaded extends WorkTypeState {
  final List<WorkTypeEntity> workTypes;
  final bool hasNextPage;
  final int totalCount;
  final bool isLoadingMore;

  const WorkTypesLoaded({
    required this.workTypes,
    this.hasNextPage = false,
    this.totalCount = 0,
    this.isLoadingMore = false,
  });

  WorkTypesLoaded copyWith({
    List<WorkTypeEntity>? workTypes,
    bool? hasNextPage,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return WorkTypesLoaded(
      workTypes: workTypes ?? this.workTypes,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [workTypes, hasNextPage, totalCount, isLoadingMore];
}

class WorkTypeCreated extends WorkTypeState {
  final WorkTypeEntity workType;

  const WorkTypeCreated(this.workType);

  @override
  List<Object> get props => [workType];
}

class WorkTypeUpdated extends WorkTypeState {
  final int workTypeId;

  const WorkTypeUpdated(this.workTypeId);

  @override
  List<Object> get props => [workTypeId];
}

class WorkTypeDeleted extends WorkTypeState {
  final int workTypeId;

  const WorkTypeDeleted(this.workTypeId);

  @override
  List<Object> get props => [workTypeId];
}

class WorkTypeError extends WorkTypeState {
  final String message;

  const WorkTypeError(this.message);

  @override
  List<Object> get props => [message];
}
