import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingsLoaded extends BookingState {
  final List<BookingEntity> bookings;
  final bool hasNextPage;
  final int totalCount;
  final bool isLoadingMore;

  const BookingsLoaded({
    required this.bookings,
    this.hasNextPage = false,
    this.totalCount = 0,
    this.isLoadingMore = false,
  });

  BookingsLoaded copyWith({
    List<BookingEntity>? bookings,
    bool? hasNextPage,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return BookingsLoaded(
      bookings: bookings ?? this.bookings,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [bookings, hasNextPage, totalCount, isLoadingMore];
}

class BookingStatusUpdated extends BookingState {
  final int bookingId;

  const BookingStatusUpdated(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object> get props => [message];
}
