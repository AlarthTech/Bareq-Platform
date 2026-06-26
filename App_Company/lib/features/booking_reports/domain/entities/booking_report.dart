import 'package:equatable/equatable.dart';

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

  bool get isOpen => status == 0;
  bool get isActive => status == 0 || status == 1;
  bool get isTerminal => status == 2 || status == 3;

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

class BookingReportFilters extends Equatable {
  const BookingReportFilters({
    this.status,
    this.bookingId,
    this.customerId,
    this.workerId,
    this.fromDate,
    this.toDate,
  });

  final int? status;
  final int? bookingId;
  final int? customerId;
  final int? workerId;
  final DateTime? fromDate;
  final DateTime? toDate;

  BookingReportFilters copyWith({
    int? status,
    int? bookingId,
    int? customerId,
    int? workerId,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearStatus = false,
  }) {
    return BookingReportFilters(
      status: clearStatus ? null : (status ?? this.status),
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      workerId: workerId ?? this.workerId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bookingId,
        customerId,
        workerId,
        fromDate,
        toDate,
      ];
}
