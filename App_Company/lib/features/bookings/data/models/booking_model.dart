import '../../domain/entities/booking_entity.dart';
import '../../../../core/utils/date_formatter.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    super.userName,
    super.customerName,
    super.customerPhone,
    super.workerId,
    super.workerName,
    super.bookingDate,
    super.startTime,
    super.endTime,
    required super.status,
    super.rejectionReason,
    super.workTypeName,
    super.companyName,
    super.address,
    super.userLocationId,
    super.locationName,
    super.lat,
    super.lng,
    super.location,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.isWorkerArrivalConfirmed,
    super.workerArrivalConfirmedAt,
  });

  static String? _companyNameFromJson(Map<String, dynamic> json) {
    final direct = json['companyName'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();
    final company = json['company'];
    if (company is Map<String, dynamic>) {
      final n = company['name'] ?? company['companyName'] ?? company['title'];
      if (n is String && n.trim().isNotEmpty) return n.trim();
    }
    if (company is String && company.trim().isNotEmpty) return company.trim();
    return null;
  }

  static double? _coord(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static bool _boolFromJson(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as String?;
    return BookingModel(
      id: json['id'] as int? ?? json['bookingId'] as int? ?? 0,
      userName: json['userName'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      workerId: json['workerId'] as int? ?? json['maidId'] as int?,
      workerName: json['workerName'] as String? ?? json['maidName'] as String?,
      bookingDate: json['bookingDate'] != null
          ? DateFormatter.parseDate(json['bookingDate'] as String)
          : json['date'] != null
              ? DateFormatter.parseDate(json['date'] as String)
              : null,
      startTime: json['startTime'] as String? ??
          json['startDate'] as String? ??
          json['time'] as String?,
      endTime: json['endTime'] as String? ?? json['endDate'] as String?,
      status: json['status'] as int? ?? 0,
      rejectionReason: json['rejectionReason'] as String?,
      workTypeName: json['workTypeName'] as String?,
      companyName: _companyNameFromJson(json),
      address: address,
      userLocationId: json['userLocationId'] as int?,
      locationName: json['locationName'] as String?,
      lat: _coord(json['lat']),
      lng: _coord(json['lng']),
      location: json['location'] as String? ?? address,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateFormatter.parseDate(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateFormatter.parseDate(json['updatedAt'] as String)
          : null,
      isWorkerArrivalConfirmed: _boolFromJson(
        json['isWorkerArrivalConfirmed'] ?? json['workerArrivalConfirmed'],
      ),
      workerArrivalConfirmedAt: json['workerArrivalConfirmedAt'] != null
          ? DateFormatter.parseDate(json['workerArrivalConfirmedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'workerId': workerId,
      'workerName': workerName,
      'bookingDate': bookingDate?.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'rejectionReason': rejectionReason,
      'workTypeName': workTypeName,
      'companyName': companyName,
      'address': address,
      'userLocationId': userLocationId,
      'locationName': locationName,
      'lat': lat,
      'lng': lng,
      'location': location,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isWorkerArrivalConfirmed': isWorkerArrivalConfirmed,
      'workerArrivalConfirmedAt': workerArrivalConfirmedAt?.toIso8601String(),
    };
  }

  BookingEntity toEntity() {
    return BookingEntity(
      id: id,
      userName: userName,
      customerName: customerName,
      customerPhone: customerPhone,
      workerId: workerId,
      workerName: workerName,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      status: status,
      rejectionReason: rejectionReason,
      workTypeName: workTypeName,
      companyName: companyName,
      address: address,
      userLocationId: userLocationId,
      locationName: locationName,
      lat: lat,
      lng: lng,
      location: location,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isWorkerArrivalConfirmed: isWorkerArrivalConfirmed,
      workerArrivalConfirmedAt: workerArrivalConfirmedAt,
    );
  }
}
