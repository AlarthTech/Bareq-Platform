/// Backend booking status values (CleaningHouse API).
///
/// | Code | Meaning |
/// |------|---------|
/// | 0 | Pending |
/// | 1 | Approved |
/// | 2 | On the way |
/// | 3 | Completed |
/// | 4 | Canceled |
/// | 5 | Rejected |
///
/// **Customers (non-admin):** 0 → 4 (cancel); 1 or 2 → 3 (mark completed). Terminals 3–5 immutable.
abstract final class BookingStatusCodes {
  static const int pending = 0;
  static const int approved = 1;
  static const int onTheWay = 2;
  static const int completed = 3;
  static const int canceled = 4;
  static const int rejected = 5;

  static bool isTerminal(int status) =>
      status == completed || status == canceled || status == rejected;

  /// Worker time slot still reserved for active / in-flight bookings.
  static bool holdsWorkerSlot(int status) => !isTerminal(status);

  static bool isInProgress(int status) =>
      status == approved || status == onTheWay;

  /// Active customer booking shown on home (pending → on the way).
  static bool isOngoing(int status) =>
      status == pending || status == approved || status == onTheWay;

  /// Timeline step index on home: 0 = pending, 1 = approved, 2 = on the way.
  static int timelineStepIndex(int status) {
    switch (status) {
      case approved:
        return 1;
      case onTheWay:
        return 2;
      case pending:
      default:
        return 0;
    }
  }

  /// Maps API / hub status labels to numeric codes.
  static int? fromApiLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    final normalized = label.trim().toLowerCase().replaceAll('_', ' ');
    switch (normalized) {
      case 'pending':
        return pending;
      case 'approved':
      case 'assigned':
        return approved;
      case 'on the way':
      case 'on_the_way':
      case 'in progress':
      case 'in_progress':
        return onTheWay;
      case 'completed':
        return completed;
      case 'cancelled':
      case 'canceled':
        return canceled;
      case 'rejected':
        return rejected;
      default:
        return int.tryParse(normalized);
    }
  }
}
