import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_report.dart';

sealed class UpdateBookingReportStatusState extends Equatable {
  const UpdateBookingReportStatusState();

  @override
  List<Object?> get props => [];
}

class UpdateBookingReportStatusInitial extends UpdateBookingReportStatusState {
  const UpdateBookingReportStatusInitial();
}

class UpdateBookingReportStatusLoading extends UpdateBookingReportStatusState {
  const UpdateBookingReportStatusLoading();
}

class UpdateBookingReportStatusSuccess extends UpdateBookingReportStatusState {
  const UpdateBookingReportStatusSuccess(this.report);

  final BookingReport report;

  @override
  List<Object?> get props => [report];
}

class UpdateBookingReportStatusError extends UpdateBookingReportStatusState {
  const UpdateBookingReportStatusError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
