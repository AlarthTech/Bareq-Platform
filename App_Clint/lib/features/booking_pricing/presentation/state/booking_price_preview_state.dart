import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_price_breakdown.dart';

sealed class BookingPricePreviewState extends Equatable {
  const BookingPricePreviewState();

  @override
  List<Object?> get props => [];
}

class BookingPricePreviewInitial extends BookingPricePreviewState {
  const BookingPricePreviewInitial();
}

class BookingPricePreviewLoading extends BookingPricePreviewState {
  const BookingPricePreviewLoading();
}

class BookingPricePreviewLoaded extends BookingPricePreviewState {
  const BookingPricePreviewLoaded(this.breakdown);

  final BookingPriceBreakdown breakdown;

  @override
  List<Object?> get props => [breakdown];
}

class BookingPricePreviewError extends BookingPricePreviewState {
  const BookingPricePreviewError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
