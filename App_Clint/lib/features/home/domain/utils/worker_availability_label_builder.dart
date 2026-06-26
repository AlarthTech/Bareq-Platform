import 'package:intl/intl.dart';

/// Builds display labels when the API omits `availabilityLabel` (legacy endpoints).
/// Does not use booking lists — only boolean/date fields from worker responses.
abstract final class WorkerAvailabilityLabelBuilder {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String formatDay(DateTime day, {String localeName = 'en'}) =>
      DateFormat.MMMd(localeName).format(day);

  /// Available-workers list for [selectedDate] (legacy `isAvailable` on that day).
  static String? forSelectedDate({
    required DateTime selectedDate,
    required bool isAvailableOnDate,
    String localeName = 'en',
  }) {
    if (!isAvailableOnDate) return null;
    final selected = dateOnly(selectedDate);
    final today = dateOnly(DateTime.now());
    if (selected == today) return 'Available Today';
    return 'Available on ${formatDay(selected, localeName: localeName)}';
  }

  /// Top-rated carousel when `availabilityLabel` is not returned by the server.
  static String? forTopRated({
    required bool isAvailableToday,
    DateTime? nextAvailableDate,
    String localeName = 'en',
  }) {
    if (isAvailableToday) return 'Available Today';

    final next = nextAvailableDate;
    if (next == null) return null;

    final nextDay = dateOnly(next);
    final today = dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    if (nextDay == tomorrow) return 'Available Tomorrow';
    return 'Available on ${formatDay(nextDay, localeName: localeName)}';
  }
}
