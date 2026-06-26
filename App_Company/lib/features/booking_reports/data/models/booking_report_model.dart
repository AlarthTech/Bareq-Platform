import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_report.dart';

class BookingReportModel extends BookingReport {
  const BookingReportModel({
    required super.id,
    required super.bookingId,
    required super.customerId,
    required super.customerName,
    required super.companyId,
    required super.companyName,
    super.workerId,
    super.workerName,
    required super.reason,
    super.description,
    required super.status,
    required super.statusName,
    super.adminResolutionNotes,
    super.resolvedByAdminId,
    super.resolvedByAdminName,
    super.resolvedAt,
    required super.createdAt,
    super.updatedAt,
    required super.bookingStatus,
    required super.bookingStatusName,
  });

  factory BookingReportModel.fromJson(Map<String, dynamic> json) {
    return BookingReportModel(
      id: json['id'] as int? ?? 0,
      bookingId: json['bookingId'] as int? ?? 0,
      customerId: json['customerId'] as int? ?? 0,
      customerName: json['customerName'] as String? ?? '—',
      companyId: json['companyId'] as int? ?? 0,
      companyName: json['companyName'] as String? ?? '—',
      workerId: json['workerId'] as int?,
      workerName: json['workerName'] as String?,
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as int? ?? 0,
      statusName: json['statusName'] as String? ?? '—',
      adminResolutionNotes: json['adminResolutionNotes'] as String?,
      resolvedByAdminId: json['resolvedByAdminId'] as int?,
      resolvedByAdminName: json['resolvedByAdminName'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateFormatter.parseDate(json['resolvedAt'] as String)
          : null,
      createdAt: DateFormatter.parseDate(json['createdAt'] as String) ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateFormatter.parseDate(json['updatedAt'] as String)
          : null,
      bookingStatus: json['bookingStatus'] as int? ?? 0,
      bookingStatusName: json['bookingStatusName'] as String? ?? '—',
    );
  }

  BookingReport toEntity() => this;
}
