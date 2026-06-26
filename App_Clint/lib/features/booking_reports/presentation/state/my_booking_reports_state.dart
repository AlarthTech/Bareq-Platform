import '../../domain/entities/booking_report.dart';

sealed class MyBookingReportsState {
  const MyBookingReportsState();
}

class MyBookingReportsInitial extends MyBookingReportsState {
  const MyBookingReportsInitial();
}

class MyBookingReportsLoading extends MyBookingReportsState {
  const MyBookingReportsLoading();
}

class MyBookingReportsLoaded extends MyBookingReportsState {
  const MyBookingReportsLoaded({
    required this.reports,
    required this.hasNextPage,
    required this.page,
    this.isLoadingMore = false,
  });

  final List<BookingReport> reports;
  final bool hasNextPage;
  final int page;
  final bool isLoadingMore;

  MyBookingReportsLoaded copyWith({
    List<BookingReport>? reports,
    bool? hasNextPage,
    int? page,
    bool? isLoadingMore,
  }) {
    return MyBookingReportsLoaded(
      reports: reports ?? this.reports,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MyBookingReportsError extends MyBookingReportsState {
  const MyBookingReportsError(this.message);

  final String message;
}
