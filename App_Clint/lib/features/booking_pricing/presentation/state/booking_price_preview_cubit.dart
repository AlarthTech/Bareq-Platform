import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_price_preview_params.dart';
import '../../domain/usecases/preview_booking_price.dart';
import 'booking_price_preview_state.dart';

class BookingPricePreviewCubit extends Cubit<BookingPricePreviewState> {
  BookingPricePreviewCubit(this._previewBookingPrice)
      : super(const BookingPricePreviewInitial());

  final PreviewBookingPrice _previewBookingPrice;

  Future<void> loadPreview(BookingPricePreviewParams params) async {
    emit(const BookingPricePreviewLoading());
    final result = await _previewBookingPrice(params);
    result.fold(
      (failure) => emit(BookingPricePreviewError(failure.message)),
      (breakdown) => emit(BookingPricePreviewLoaded(breakdown)),
    );
  }

  void reset() => emit(const BookingPricePreviewInitial());
}
