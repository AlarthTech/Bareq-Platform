class CreateBookingReportArgs {
  const CreateBookingReportArgs({
    required this.bookingId,
    required this.bookingLabel,
    required this.bookingStatus,
    this.returnRoute,
  });

  final int bookingId;
  final String bookingLabel;
  final int bookingStatus;
  final String? returnRoute;
}
