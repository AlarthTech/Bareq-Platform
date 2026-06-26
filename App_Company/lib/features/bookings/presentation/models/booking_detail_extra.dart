import '../../domain/entities/booking_entity.dart';
import '../bloc/booking_bloc.dart';

/// Passed via [GoRouterState.extra] when opening [BookingDetailScreen].
class BookingDetailExtra {
  const BookingDetailExtra({
    required this.booking,
    required this.bookingBloc,
  });

  final BookingEntity booking;
  final BookingBloc bookingBloc;
}
