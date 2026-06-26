import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class BookingEntity extends Equatable {
  final int id;
  final String? userName;
  final String? customerName;
  final String? customerPhone;
  final int? workerId;
  final String? workerName;
  final DateTime? bookingDate;
  final String? startTime;
  final String? endTime;
  /// 0 Pending · 1 Approved · 2 On the way · 3 Completed · 4 Canceled · 5 Rejected
  final int status;
  final String? rejectionReason;
  final String? workTypeName;
  final String? companyName;
  /// Customer address label (from saved location name or typed address).
  final String? address;
  /// Non-null when customer picked a saved location at booking time.
  final int? userLocationId;
  final String? locationName;
  final double? lat;
  final double? lng;
  /// Legacy / fallback text location field.
  final String? location;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// Customer confirmed worker arrival (UI signal while backend status stays OnTheWay).
  final bool isWorkerArrivalConfirmed;
  final DateTime? workerArrivalConfirmedAt;

  const BookingEntity({
    required this.id,
    this.userName,
    this.customerName,
    this.customerPhone,
    this.workerId,
    this.workerName,
    this.bookingDate,
    this.startTime,
    this.endTime,
    required this.status,
    this.rejectionReason,
    this.workTypeName,
    this.companyName,
    this.address,
    this.userLocationId,
    this.locationName,
    this.lat,
    this.lng,
    this.location,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.isWorkerArrivalConfirmed = false,
    this.workerArrivalConfirmedAt,
  });

  String get customerDisplayName => userName ?? customerName ?? '-';

  /// Primary address line for UI (API `address` or legacy `location`).
  String? get displayAddress {
    final a = address?.trim();
    if (a != null && a.isNotEmpty) return a;
    final l = location?.trim();
    if (l != null && l.isNotEmpty) return l;
    return null;
  }

  bool get hasMapCoordinates => lat != null && lng != null;

  bool get isSavedCustomerLocation => userLocationId != null;

  bool get isCleaningStartedDisplay => AppConstants.isCleaningStartedDisplay(
        status: status,
        isWorkerArrivalConfirmed: isWorkerArrivalConfirmed,
      );

  BookingEntity copyWith({
    int? status,
    DateTime? updatedAt,
    bool? isWorkerArrivalConfirmed,
    DateTime? workerArrivalConfirmedAt,
  }) {
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
      status: status ?? this.status,
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
      updatedAt: updatedAt ?? this.updatedAt,
      isWorkerArrivalConfirmed:
          isWorkerArrivalConfirmed ?? this.isWorkerArrivalConfirmed,
      workerArrivalConfirmedAt:
          workerArrivalConfirmedAt ?? this.workerArrivalConfirmedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userName,
        customerName,
        customerPhone,
        workerId,
        workerName,
        bookingDate,
        startTime,
        endTime,
        status,
        rejectionReason,
        workTypeName,
        companyName,
        address,
        userLocationId,
        locationName,
        lat,
        lng,
        location,
        notes,
        createdAt,
        updatedAt,
        isWorkerArrivalConfirmed,
        workerArrivalConfirmedAt,
      ];
}
