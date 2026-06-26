import 'package:equatable/equatable.dart';

/// Booking entity representing a user's booking in the domain layer
class Booking extends Equatable {
  final int id;
  final int userId;
  final String userName;
  final int companyId;
  final String companyName;
  final int workerId;
  final String workerName;
  final int workerWorkTypeId;
  final String? workTypeName;
  final DateTime bookingDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startDateDisplay;
  final String? endDateDisplay;
  final String address;
  final int? userLocationId;
  final String? locationName;
  final double? lat;
  final double? lng;
  /// Numeric status codes: see `BookingStatusCodes`.
  final int status;
  final DateTime createdAt;
  final String? rejectionReason;
  final double servicePrice;
  final double platformFeeAmount;
  final double totalPrice;
  final bool isMonthlyPricing;
  final String? paymentMethod;
  final bool isWorkerArrivalConfirmed;
  final DateTime? workerArrivalConfirmedAt;
  final bool walletAmountReserved;
  final bool walletAmountCaptured;
  final DateTime? walletCapturedAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.companyId,
    required this.companyName,
    required this.workerId,
    required this.workerName,
    required this.workerWorkTypeId,
    this.workTypeName,
    required this.bookingDate,
    this.startDate,
    this.endDate,
    this.startDateDisplay,
    this.endDateDisplay,
    required this.address,
    this.userLocationId,
    this.locationName,
    this.lat,
    this.lng,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.servicePrice = 0,
    this.platformFeeAmount = 0,
    this.totalPrice = 0,
    this.isMonthlyPricing = false,
    this.paymentMethod,
    this.isWorkerArrivalConfirmed = false,
    this.workerArrivalConfirmedAt,
    this.walletAmountReserved = false,
    this.walletAmountCaptured = false,
    this.walletCapturedAt,
  });

  bool get hasStoredPricing => totalPrice > 0 || servicePrice > 0;

  bool get isWalletPayment =>
      paymentMethod?.trim().toLowerCase() == 'wallet' ||
      walletAmountReserved ||
      walletAmountCaptured;

  /// Normalized key for UI / filters (matches l10n keys where applicable).
  String get statusString {
    switch (status) {
      case 0:
        return 'pending';
      case 1:
        return 'approved';
      case 2:
        return 'on_the_way';
      case 3:
        return 'completed';
      case 4:
        return 'canceled';
      case 5:
        return 'rejected';
      default:
        return 'pending';
    }
  }

  Booking copyWith({
    int? status,
    String? rejectionReason,
    bool? isWorkerArrivalConfirmed,
    DateTime? workerArrivalConfirmedAt,
    bool? walletAmountReserved,
    bool? walletAmountCaptured,
    DateTime? walletCapturedAt,
  }) {
    return Booking(
      id: id,
      userId: userId,
      userName: userName,
      companyId: companyId,
      companyName: companyName,
      workerId: workerId,
      workerName: workerName,
      workerWorkTypeId: workerWorkTypeId,
      workTypeName: workTypeName,
      bookingDate: bookingDate,
      startDate: startDate,
      endDate: endDate,
      startDateDisplay: startDateDisplay,
      endDateDisplay: endDateDisplay,
      address: address,
      userLocationId: userLocationId,
      locationName: locationName,
      lat: lat,
      lng: lng,
      status: status ?? this.status,
      createdAt: createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      servicePrice: servicePrice,
      platformFeeAmount: platformFeeAmount,
      totalPrice: totalPrice,
      isMonthlyPricing: isMonthlyPricing,
      paymentMethod: paymentMethod,
      isWorkerArrivalConfirmed:
          isWorkerArrivalConfirmed ?? this.isWorkerArrivalConfirmed,
      workerArrivalConfirmedAt:
          workerArrivalConfirmedAt ?? this.workerArrivalConfirmedAt,
      walletAmountReserved: walletAmountReserved ?? this.walletAmountReserved,
      walletAmountCaptured: walletAmountCaptured ?? this.walletAmountCaptured,
      walletCapturedAt: walletCapturedAt ?? this.walletCapturedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        companyId,
        companyName,
        workerId,
        workerName,
        workerWorkTypeId,
        workTypeName,
        bookingDate,
        startDate,
        endDate,
        startDateDisplay,
        endDateDisplay,
        address,
        userLocationId,
        locationName,
        lat,
        lng,
        status,
        createdAt,
        rejectionReason,
        servicePrice,
        platformFeeAmount,
        totalPrice,
        isMonthlyPricing,
        paymentMethod,
        isWorkerArrivalConfirmed,
        workerArrivalConfirmedAt,
        walletAmountReserved,
        walletAmountCaptured,
        walletCapturedAt,
      ];
}
