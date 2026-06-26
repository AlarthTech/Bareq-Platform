import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/review.dart';
import '../../domain/usecases/review_usecases.dart';

sealed class CreateReviewState extends Equatable {
  const CreateReviewState();

  @override
  List<Object?> get props => [];
}

class CreateReviewInitial extends CreateReviewState {}

class CreateReviewLoading extends CreateReviewState {}

class CreateReviewSuccess extends CreateReviewState {
  const CreateReviewSuccess(this.review);

  final Review review;

  @override
  List<Object?> get props => [review];
}

class CreateReviewError extends CreateReviewState {
  const CreateReviewError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CreateReviewCubit extends Cubit<CreateReviewState> {
  CreateReviewCubit({
    required CreateReviewUseCase createReviewUseCase,
  })  : _createReviewUseCase = createReviewUseCase,
        super(CreateReviewInitial());

  final CreateReviewUseCase _createReviewUseCase;

  Future<void> submit({
    required int bookingId,
    required int workerId,
    required int rating,
    String? comment,
  }) async {
    emit(CreateReviewLoading());
    final result = await _createReviewUseCase(
      bookingId: bookingId,
      workerId: workerId,
      rating: rating,
      comment: comment,
    );
    result.fold(
      (f) => emit(CreateReviewError(f.message)),
      (review) => emit(CreateReviewSuccess(review)),
    );
  }
}
