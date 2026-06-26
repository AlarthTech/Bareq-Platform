import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadDashboardDataEvent extends DashboardEvent {
  final int companyId;
  
  const LoadDashboardDataEvent(this.companyId);
  
  @override
  List<Object> get props => [companyId];
}

class PatchBookingStatusDashboardEvent extends DashboardEvent {
  const PatchBookingStatusDashboardEvent({
    required this.bookingId,
    required this.status,
  });

  final int bookingId;
  final int status;

  @override
  List<Object> get props => [bookingId, status];
}
