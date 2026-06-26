import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bookings/domain/usecases/get_bookings_usecase.dart';
import '../../../workers/domain/usecases/get_workers_usecase.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../workers/domain/entities/worker_entity.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/health_certificate_helper.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required this.getBookingsUseCase,
    required this.getWorkersUseCase,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<PatchBookingStatusDashboardEvent>(_onPatchBookingStatus);
  }

  final GetBookingsUseCase getBookingsUseCase;
  final GetWorkersUseCase getWorkersUseCase;

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    try {
      final bookingsResult = await getBookingsUseCase(
        GetBookingsParams(companyId: event.companyId),
      );
      final bookingsPage = bookingsResult.fold(
        (failure) => null,
        (page) => page,
      );
      final bookings = bookingsPage?.items ?? <BookingEntity>[];

      final workersResult = await getWorkersUseCase(
        GetWorkersParams(companyId: event.companyId),
      );
      final workersPage = workersResult.fold(
        (failure) => null,
        (page) => page,
      );
      final workers = workersPage?.items ?? <WorkerEntity>[];

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      bool isSameDay(DateTime? d) {
        if (d == null) return false;
        final x = DateTime(d.year, d.month, d.day);
        return x == todayStart;
      }

      final todayBookings = bookings
          .where((b) => isSameDay(b.bookingDate))
          .toList();

      final pendingBookings =
          bookings.where((b) => b.status == AppConstants.statusPending).length;
      final ongoingBookings = bookings
          .where((b) =>
              b.status == AppConstants.statusApproved ||
              b.status == AppConstants.statusOnTheWay)
          .length;

      final monthlyCompletedBookings = bookings.where((b) {
        if (b.status != AppConstants.statusCompleted) return false;
        final d = b.bookingDate ?? b.updatedAt ?? b.createdAt;
        if (d == null) return false;
        return !d.isBefore(monthStart);
      }).length;

      final activeWorkersCount = workers.where((w) => w.isActive).length;
      final availableWorkersCount =
          workers.where((w) => w.isActive && w.isAvailable).length;

      final bookingsNeedingAttention = bookings.where((booking) {
        if (booking.status != AppConstants.statusPending) return false;
        if (booking.createdAt == null) return false;
        final hoursPending = now.difference(booking.createdAt!).inHours;
        return hoursPending > AppConstants.bookingAlertHours;
      }).toList();

      final workersWithExpiringHealthCertificates = workers.where((worker) {
        return HealthCertificateHelper.needsAttention(
          worker.healthCertificateExpiryDate,
        );
      }).toList();

      final recentBookings = bookings.take(8).toList();
      final cleaningInProgressBookings = bookings
          .where((b) => b.isCleaningStartedDisplay)
          .toList();

      emit(
        DashboardLoaded(
          DashboardData(
            todayBookingsCount: todayBookings.length,
            activeWorkersCount: activeWorkersCount,
            availableWorkersCount: availableWorkersCount,
            monthlyCompletedBookings: monthlyCompletedBookings,
            pendingBookings: pendingBookings,
            ongoingBookings: ongoingBookings,
            bookingsNeedingAttention: bookingsNeedingAttention,
            workersWithExpiringHealthCertificates:
                workersWithExpiringHealthCertificates,
            recentBookings: recentBookings,
            cleaningInProgressBookings: cleaningInProgressBookings,
            todayBookings: todayBookings,
          ),
        ),
      );
    } catch (e) {
      emit(DashboardError('حدث خطأ في تحميل البيانات: ${e.toString()}'));
    }
  }

  void _onPatchBookingStatus(
    PatchBookingStatusDashboardEvent event,
    Emitter<DashboardState> emit,
  ) {
    final current = state;
    if (current is! DashboardLoaded) return;

    final data = current.data;
    final index =
        data.recentBookings.indexWhere((b) => b.id == event.bookingId);
    if (index < 0) return;

    final booking = data.recentBookings[index];
    if (booking.status == event.status) return;

    final updatedBooking = booking.copyWith(
      status: event.status,
      updatedAt: DateTime.now(),
    );

    final updatedRecent = List<BookingEntity>.from(data.recentBookings);
    updatedRecent[index] = updatedBooking;

    final updatedToday = List<BookingEntity>.from(data.todayBookings);
    final todayIdx = updatedToday.indexWhere((b) => b.id == event.bookingId);
    if (todayIdx >= 0) updatedToday[todayIdx] = updatedBooking;

    emit(
      DashboardLoaded(
        data.copyWith(
          recentBookings: updatedRecent,
          todayBookings: updatedToday,
          pendingBookings: _adjustCount(
            data.pendingBookings,
            booking.status,
            event.status,
            AppConstants.statusPending,
          ),
          ongoingBookings: _adjustOngoingCount(
            data.ongoingBookings,
            booking.status,
            event.status,
          ),
          bookingsNeedingAttention: data.bookingsNeedingAttention
              .where((b) => b.id != event.bookingId)
              .toList(),
          cleaningInProgressBookings: _patchCleaningList(
            data.cleaningInProgressBookings,
            updatedBooking,
          ),
        ),
      ),
    );
  }

  List<BookingEntity> _patchCleaningList(
    List<BookingEntity> current,
    BookingEntity updated,
  ) {
    final without = current.where((b) => b.id != updated.id).toList();
    if (updated.isCleaningStartedDisplay) {
      return [updated, ...without];
    }
    return without;
  }

  int _adjustCount(int current, int oldStatus, int newStatus, int target) {
    var count = current;
    if (oldStatus == target && count > 0) count--;
    if (newStatus == target) count++;
    return count;
  }

  int _adjustOngoingCount(int current, int oldStatus, int newStatus) {
    final wasOngoing = oldStatus == AppConstants.statusApproved ||
        oldStatus == AppConstants.statusOnTheWay;
    final isOngoing = newStatus == AppConstants.statusApproved ||
        newStatus == AppConstants.statusOnTheWay;

    var count = current;
    if (wasOngoing && count > 0) count--;
    if (isOngoing) count++;
    return count;
  }
}

extension on DashboardData {
  DashboardData copyWith({
    List<BookingEntity>? recentBookings,
    List<BookingEntity>? todayBookings,
    List<BookingEntity>? cleaningInProgressBookings,
    List<BookingEntity>? bookingsNeedingAttention,
    int? pendingBookings,
    int? ongoingBookings,
  }) {
    return DashboardData(
      todayBookingsCount: todayBookings?.length ?? todayBookingsCount,
      activeWorkersCount: activeWorkersCount,
      availableWorkersCount: availableWorkersCount,
      monthlyCompletedBookings: monthlyCompletedBookings,
      pendingBookings: pendingBookings ?? this.pendingBookings,
      ongoingBookings: ongoingBookings ?? this.ongoingBookings,
      bookingsNeedingAttention:
          bookingsNeedingAttention ?? this.bookingsNeedingAttention,
      workersWithExpiringHealthCertificates:
          workersWithExpiringHealthCertificates,
      recentBookings: recentBookings ?? this.recentBookings,
      cleaningInProgressBookings:
          cleaningInProgressBookings ?? this.cleaningInProgressBookings,
      todayBookings: todayBookings ?? this.todayBookings,
    );
  }
}
