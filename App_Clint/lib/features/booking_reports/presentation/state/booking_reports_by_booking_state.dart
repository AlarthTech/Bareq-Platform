import '../../domain/entities/booking_report.dart';

sealed class BookingReportsByBookingState {
  const BookingReportsByBookingState();
}

class BookingReportsByBookingInitial extends BookingReportsByBookingState {
  const BookingReportsByBookingInitial();
}

class BookingReportsByBookingLoading extends BookingReportsByBookingState {
  const BookingReportsByBookingLoading();
}

class BookingReportsByBookingLoaded extends BookingReportsByBookingState {
  const BookingReportsByBookingLoaded({
    required this.reports,
    required this.hasNextPage,
    required this.page,
    this.isLoadingMore = false,
  });

  final List<BookingReport> reports;
  final bool hasNextPage;
  final int page;
  final bool isLoadingMore;

  bool get hasActiveReport => reports.any((report) => report.isActive);

  BookingReportsByBookingLoaded copyWith({
    List<BookingReport>? reports,
    bool? hasNextPage,
    int? page,
    bool? isLoadingMore,
  }) {
    return BookingReportsByBookingLoaded(
      reports: reports ?? this.reports,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class BookingReportsByBookingError extends BookingReportsByBookingState {
  const BookingReportsByBookingError(this.message);

  final String message;
}
