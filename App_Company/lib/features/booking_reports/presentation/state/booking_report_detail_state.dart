import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_report.dart';

sealed class BookingReportDetailState extends Equatable {
  const BookingReportDetailState();

  @override
  List<Object?> get props => [];
}

class BookingReportDetailInitial extends BookingReportDetailState {
  const BookingReportDetailInitial();
}

class BookingReportDetailLoading extends BookingReportDetailState {
  const BookingReportDetailLoading();
}

class BookingReportDetailLoaded extends BookingReportDetailState {
  const BookingReportDetailLoaded(this.report);

  final BookingReport report;

  @override
  List<Object?> get props => [report];
}

class BookingReportDetailError extends BookingReportDetailState {
  const BookingReportDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
