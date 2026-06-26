import 'package:equatable/equatable.dart';

enum BookingReportStatus {
  open,
  inReview,
  resolved,
  rejected;

  static BookingReportStatus fromApi(int value) => switch (value) {
        0 => BookingReportStatus.open,
        1 => BookingReportStatus.inReview,
        2 => BookingReportStatus.resolved,
        3 => BookingReportStatus.rejected,
        _ => BookingReportStatus.open,
      };
}

class BookingReport extends Equatable {
  const BookingReport({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.companyId,
    required this.companyName,
    this.workerId,
    this.workerName,
    required this.reason,
    this.description,
    required this.status,
    required this.statusName,
    this.adminResolutionNotes,
    this.resolvedByAdminId,
    this.resolvedByAdminName,
    this.resolvedAt,
    required this.createdAt,
    this.updatedAt,
    required this.bookingStatus,
    required this.bookingStatusName,
  });

  final int id;
  final int bookingId;
  final int customerId;
  final String customerName;
  final int companyId;
  final String companyName;
  final int? workerId;
  final String? workerName;
  final String reason;
  final String? description;
  final int status;
  final String statusName;
  final String? adminResolutionNotes;
  final int? resolvedByAdminId;
  final String? resolvedByAdminName;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int bookingStatus;
  final String bookingStatusName;

  BookingReportStatus get statusEnum => BookingReportStatus.fromApi(status);

  bool get isActive => status == 0 || status == 1;

  bool get showAdminNotes =>
      (status == 2 || status == 3) &&
      adminResolutionNotes != null &&
      adminResolutionNotes!.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        bookingId,
        customerId,
        customerName,
        companyId,
        companyName,
        workerId,
        workerName,
        reason,
        description,
        status,
        statusName,
        adminResolutionNotes,
        resolvedByAdminId,
        resolvedByAdminName,
        resolvedAt,
        createdAt,
        updatedAt,
        bookingStatus,
        bookingStatusName,
      ];
}
