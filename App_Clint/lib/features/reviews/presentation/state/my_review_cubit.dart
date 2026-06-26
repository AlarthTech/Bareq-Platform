import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/review.dart';
import '../../domain/usecases/review_usecases.dart';

sealed class MyReviewState extends Equatable {
  const MyReviewState();

  @override
  List<Object?> get props => [];
}

class MyReviewInitial extends MyReviewState {}

class MyReviewLoading extends MyReviewState {}

class MyReviewLoaded extends MyReviewState {
  const MyReviewLoaded(this.review, {this.editing = false});

  final Review review;
  final bool editing;

  MyReviewLoaded copyWith({Review? review, bool? editing}) {
    return MyReviewLoaded(
      review ?? this.review,
      editing: editing ?? this.editing,
    );
  }

  @override
  List<Object?> get props => [review, editing];
}

class MyReviewEmpty extends MyReviewState {}

class MyReviewError extends MyReviewState {
  const MyReviewError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class MyReviewDeleting extends MyReviewState {
  const MyReviewDeleting(this.review);

  final Review review;

  @override
  List<Object?> get props => [review];
}

class MyReviewDeleted extends MyReviewState {}

class MyReviewCubit extends Cubit<MyReviewState> {
  MyReviewCubit({
    required GetReviewsByBookingUseCase getReviewsByBookingUseCase,
    required UpdateReviewUseCase updateReviewUseCase,
    required DeleteReviewUseCase deleteReviewUseCase,
  })  : _getReviewsByBookingUseCase = getReviewsByBookingUseCase,
        _updateReviewUseCase = updateReviewUseCase,
        _deleteReviewUseCase = deleteReviewUseCase,
        super(MyReviewInitial());

  final GetReviewsByBookingUseCase _getReviewsByBookingUseCase;
  final UpdateReviewUseCase _updateReviewUseCase;
  final DeleteReviewUseCase _deleteReviewUseCase;

  Future<void> load(int bookingId) async {
    emit(MyReviewLoading());
    final result = await _getReviewsByBookingUseCase(
      bookingId,
      page: 1,
      pageSize: 1,
    );
    result.fold(
      (f) => emit(MyReviewError(f.message)),
      (paged) {
        if (paged.items.isEmpty) {
          emit(MyReviewEmpty());
        } else {
          emit(MyReviewLoaded(paged.items.first));
        }
      },
    );
  }

  void startEditing() {
    final current = state;
    if (current is MyReviewLoaded) {
      emit(current.copyWith(editing: true));
    }
  }

  void cancelEditing() {
    final current = state;
    if (current is MyReviewLoaded) {
      emit(current.copyWith(editing: false));
    }
  }

  Future<void> update({
    required int rating,
    String? comment,
  }) async {
    final current = state;
    if (current is! MyReviewLoaded) return;
    emit(MyReviewLoading());
    final result = await _updateReviewUseCase(
      reviewId: current.review.id,
      rating: rating,
      comment: comment,
    );
    result.fold(
      (f) => emit(MyReviewError(f.message)),
      (_) => emit(
        MyReviewLoaded(
          Review(
            id: current.review.id,
            bookingId: current.review.bookingId,
            userId: current.review.userId,
            userName: current.review.userName,
            workerId: current.review.workerId,
            workerName: current.review.workerName,
            rating: rating,
            comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
            createdAt: current.review.createdAt,
          ),
        ),
      ),
    );
  }

  Future<void> delete() async {
    final current = state;
    if (current is! MyReviewLoaded) return;
    emit(MyReviewDeleting(current.review));
    final result = await _deleteReviewUseCase(current.review.id);
    result.fold(
      (f) => emit(MyReviewError(f.message)),
      (_) => emit(MyReviewDeleted()),
    );
  }
}
