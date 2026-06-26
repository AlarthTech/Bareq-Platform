import '../../domain/entities/booking_report.dart';

sealed class CreateBookingReportState {
  const CreateBookingReportState();
}

class CreateBookingReportInitial extends CreateBookingReportState {
  const CreateBookingReportInitial();
}

class CreateBookingReportLoading extends CreateBookingReportState {
  const CreateBookingReportLoading();
}

class CreateBookingReportSuccess extends CreateBookingReportState {
  const CreateBookingReportSuccess(this.report);

  final BookingReport report;
}

class CreateBookingReportError extends CreateBookingReportState {
  const CreateBookingReportError(this.message);

  final String message;
}
