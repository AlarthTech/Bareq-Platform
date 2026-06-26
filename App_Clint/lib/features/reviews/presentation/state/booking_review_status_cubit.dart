import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/review_usecases.dart';

class BookingReviewStatusCubit extends Cubit<Map<int, bool>> {
  BookingReviewStatusCubit(this._hasReviewForBookingUseCase)
      : super(const {});

  final HasReviewForBookingUseCase _hasReviewForBookingUseCase;
  final Map<int, bool> _cache = {};

  bool? getCached(int bookingId) => _cache[bookingId];

  Future<bool?> check(int bookingId) async {
    if (_cache.containsKey(bookingId)) return _cache[bookingId];
    final result = await _hasReviewForBookingUseCase(bookingId);
    return result.fold(
      (_) => null,
      (hasReview) {
        _cache[bookingId] = hasReview;
        emit(Map<int, bool>.from(_cache));
        return hasReview;
      },
    );
  }

  void markReviewed(int bookingId) {
    _cache[bookingId] = true;
    emit(Map<int, bool>.from(_cache));
  }

  void markNotReviewed(int bookingId) {
    _cache[bookingId] = false;
    emit(Map<int, bool>.from(_cache));
  }

  void invalidate(int bookingId) {
    _cache.remove(bookingId);
    emit(Map<int, bool>.from(_cache));
  }
}
