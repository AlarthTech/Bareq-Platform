import '../../../../core/utils/calendar_date.dart';
import 'booking.dart';
import 'booking_status_codes.dart';

/// Calendar days when a worker's slot is taken (pending → on the way).
class WorkerSlotOccupancyIndex {
  const WorkerSlotOccupancyIndex(this._occupiedKeysByWorker);

  final Map<int, Set<int>> _occupiedKeysByWorker;

  static int dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.year * 10000 + d.month * 100 + d.day;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime? _dateKeyToDate(int key) {
    final y = key ~/ 10000;
    final m = (key % 10000) ~/ 100;
    final d = key % 100;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  static bool _isDateOnlyString(String? raw) {
    if (raw == null) return false;
    return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw.trim());
  }

  static DateTime _bookingRangeStart(Booking booking) {
    final start = booking.startDate;
    if (start != null) return _dateOnly(start);

    final display = booking.startDateDisplay;
    if (_isDateOnlyString(display)) {
      return CalendarDate.parseFromApi(display);
    }
    return _dateOnly(booking.bookingDate);
  }

  static DateTime _bookingRangeEnd(Booking booking) {
    final end = booking.endDate;
    if (end != null) return _dateOnly(end);

    final display = booking.endDateDisplay;
    if (_isDateOnlyString(display)) {
      return CalendarDate.parseFromApi(display);
    }
    return _dateOnly(booking.bookingDate);
  }

  factory WorkerSlotOccupancyIndex.fromBookings(Iterable<Booking> bookings) {
    final map = <int, Set<int>>{};
    for (final booking in bookings) {
      if (!BookingStatusCodes.holdsWorkerSlot(booking.status)) continue;
      final workerId = booking.workerId;
      if (workerId <= 0) continue;

      final occupied = map.putIfAbsent(workerId, () => <int>{});
      final start = _bookingRangeStart(booking);
      final end = _bookingRangeEnd(booking);
      final from = start.isBefore(end) ? start : end;
      final to = start.isBefore(end) ? end : start;
      for (
        var d = from;
        !d.isAfter(to);
        d = d.add(const Duration(days: 1))
      ) {
        occupied.add(dateKey(d));
      }
    }
    return WorkerSlotOccupancyIndex(map);
  }

  bool isOccupied(int workerId, DateTime day) =>
      _occupiedKeysByWorker[workerId]?.contains(dateKey(day)) ?? false;

  bool hasBookings(int workerId) =>
      (_occupiedKeysByWorker[workerId]?.isNotEmpty ?? false);

  /// Last calendar day that is fully booked for [workerId].
  DateTime? lastOccupiedDay(int workerId) {
    final keys = _occupiedKeysByWorker[workerId];
    if (keys == null || keys.isEmpty) return null;

    DateTime? latest;
    for (final key in keys) {
      final day = _dateKeyToDate(key);
      if (day == null) continue;
      if (latest == null || day.isAfter(latest)) latest = day;
    }
    return latest;
  }

  /// First calendar day strictly after the worker's last booked day.
  DateTime? firstDayAfterLastBooking(int workerId) {
    final last = lastOccupiedDay(workerId);
    if (last == null) return null;
    return _dateOnly(last).add(const Duration(days: 1));
  }

  /// Earliest day we may return as "nearest available" (never on a booked day).
  DateTime searchStartOnOrAfterBookings(int workerId, DateTime fromDate) {
    final base = _dateOnly(fromDate);
    final afterBookings = firstDayAfterLastBooking(workerId);
    if (afterBookings == null) return base;
    return afterBookings.isAfter(base) ? afterBookings : base;
  }
}
