import 'package:equatable/equatable.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../workers/domain/entities/worker_entity.dart';

class DashboardData extends Equatable {
  const DashboardData({
    required this.todayBookingsCount,
    required this.activeWorkersCount,
    required this.availableWorkersCount,
    required this.monthlyCompletedBookings,
    required this.pendingBookings,
    required this.ongoingBookings,
    required this.bookingsNeedingAttention,
    required this.workersWithExpiringHealthCertificates,
    required this.recentBookings,
    required this.cleaningInProgressBookings,
    required this.todayBookings,
  });

  /// Operational KPIs (primary dashboard).
  final int todayBookingsCount;
  final int activeWorkersCount;
  final int availableWorkersCount;
  final int monthlyCompletedBookings;

  /// Legacy / alerts (still used for patches & alerts).
  final int pendingBookings;
  final int ongoingBookings;
  final List<BookingEntity> bookingsNeedingAttention;
  final List<WorkerEntity> workersWithExpiringHealthCertificates;
  final List<BookingEntity> recentBookings;
  final List<BookingEntity> cleaningInProgressBookings;
  final List<BookingEntity> todayBookings;

  int get cleaningInProgressCount => cleaningInProgressBookings.length;

  @override
  List<Object?> get props => [
        todayBookingsCount,
        activeWorkersCount,
        availableWorkersCount,
        monthlyCompletedBookings,
        pendingBookings,
        ongoingBookings,
        bookingsNeedingAttention,
        workersWithExpiringHealthCertificates,
        recentBookings,
        cleaningInProgressBookings,
        todayBookings,
      ];
}

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.data);

  final DashboardData data;

  @override
  List<Object> get props => [data];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
