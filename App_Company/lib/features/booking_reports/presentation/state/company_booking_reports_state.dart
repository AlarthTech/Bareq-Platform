import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_report.dart';

sealed class CompanyBookingReportsState extends Equatable {
  const CompanyBookingReportsState();

  @override
  List<Object?> get props => [];
}

class CompanyBookingReportsInitial extends CompanyBookingReportsState {
  const CompanyBookingReportsInitial();
}

class CompanyBookingReportsLoading extends CompanyBookingReportsState {
  const CompanyBookingReportsLoading();
}

class CompanyBookingReportsLoaded extends CompanyBookingReportsState {
  const CompanyBookingReportsLoaded({
    required this.reports,
    required this.hasNextPage,
    required this.page,
    this.statusFilter,
    this.bookingIdFilter,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.openReportsCount,
  });

  final List<BookingReport> reports;
  final bool hasNextPage;
  final int page;
  final int? statusFilter;
  final int? bookingIdFilter;
  final bool isLoadingMore;
  final bool isRefreshing;
  final int? openReportsCount;

  CompanyBookingReportsLoaded copyWith({
    List<BookingReport>? reports,
    bool? hasNextPage,
    int? page,
    int? statusFilter,
    int? bookingIdFilter,
    bool? isLoadingMore,
    bool? isRefreshing,
    int? openReportsCount,
    bool clearStatusFilter = false,
  }) {
    return CompanyBookingReportsLoaded(
      reports: reports ?? this.reports,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      page: page ?? this.page,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      bookingIdFilter: bookingIdFilter ?? this.bookingIdFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      openReportsCount: openReportsCount ?? this.openReportsCount,
    );
  }

  @override
  List<Object?> get props => [
        reports,
        hasNextPage,
        page,
        statusFilter,
        bookingIdFilter,
        isLoadingMore,
        isRefreshing,
        openReportsCount,
      ];
}

class CompanyBookingReportsError extends CompanyBookingReportsState {
  const CompanyBookingReportsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
