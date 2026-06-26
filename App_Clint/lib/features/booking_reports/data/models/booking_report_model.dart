import '../../domain/entities/booking_report.dart';

class BookingReportModel {
  BookingReportModel({
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

  factory BookingReportModel.fromJson(Map<String, dynamic> json) {
    return BookingReportModel(
      id: _parseInt(json['id']) ?? 0,
      bookingId: _parseInt(json['bookingId']) ?? 0,
      customerId: _parseInt(json['customerId']) ?? 0,
      customerName: json['customerName']?.toString() ?? '',
      companyId: _parseInt(json['companyId']) ?? 0,
      companyName: json['companyName']?.toString() ?? '',
      workerId: _parseInt(json['workerId']),
      workerName: json['workerName']?.toString(),
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString(),
      status: _parseInt(json['status']) ?? 0,
      statusName: json['statusName']?.toString() ?? '',
      adminResolutionNotes: json['adminResolutionNotes']?.toString(),
      resolvedByAdminId: _parseInt(json['resolvedByAdminId']),
      resolvedByAdminName: json['resolvedByAdminName']?.toString(),
      resolvedAt: _parseDate(json['resolvedAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      bookingStatus: _parseInt(json['bookingStatus']) ?? 0,
      bookingStatusName: json['bookingStatusName']?.toString() ?? '',
    );
  }

  BookingReport toEntity() {
    return BookingReport(
      id: id,
      bookingId: bookingId,
      customerId: customerId,
      customerName: customerName,
      companyId: companyId,
      companyName: companyName,
      workerId: workerId,
      workerName: workerName,
      reason: reason,
      description: description,
      status: status,
      statusName: statusName,
      adminResolutionNotes: adminResolutionNotes,
      resolvedByAdminId: resolvedByAdminId,
      resolvedByAdminName: resolvedByAdminName,
      resolvedAt: resolvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      bookingStatus: bookingStatus,
      bookingStatusName: bookingStatusName,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
