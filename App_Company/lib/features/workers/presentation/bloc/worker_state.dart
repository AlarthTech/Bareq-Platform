import 'package:equatable/equatable.dart';
import '../../domain/entities/worker_entity.dart';
import '../../domain/entities/nationality_entity.dart';
import '../../domain/entities/language_entity.dart';

abstract class WorkerState extends Equatable {
  const WorkerState();

  @override
  List<Object?> get props => [];
}

class WorkerInitial extends WorkerState {
  const WorkerInitial();
}

class WorkerLoading extends WorkerState {
  const WorkerLoading();
}

class WorkersLoaded extends WorkerState {
  final List<WorkerEntity> workers;
  final bool hasNextPage;
  final int totalCount;
  final bool isLoadingMore;

  const WorkersLoaded({
    required this.workers,
    this.hasNextPage = false,
    this.totalCount = 0,
    this.isLoadingMore = false,
  });

  WorkersLoaded copyWith({
    List<WorkerEntity>? workers,
    bool? hasNextPage,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return WorkersLoaded(
      workers: workers ?? this.workers,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [workers, hasNextPage, totalCount, isLoadingMore];
}

class WorkerCreated extends WorkerState {
  final WorkerEntity worker;

  const WorkerCreated(this.worker);

  @override
  List<Object> get props => [worker];
}

class WorkerLookupsLoading extends WorkerState {
  const WorkerLookupsLoading();
}

class WorkerLookupsLoaded extends WorkerState {
  final List<NationalityEntity> nationalities;
  final List<LanguageEntity> languages;

  const WorkerLookupsLoaded({
    required this.nationalities,
    required this.languages,
  });

  @override
  List<Object> get props => [nationalities, languages];
}

class WorkerError extends WorkerState {
  final String message;

  const WorkerError(this.message);

  @override
  List<Object> get props => [message];
}
