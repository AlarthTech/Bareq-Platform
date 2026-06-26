/// Calendar-day helpers for booking dates (avoid off-by-one from timezone shifts).
class CalendarDate {
  CalendarDate._();

  /// `yyyy-MM-dd` for availability queries and other date-only params.
  static String formatDateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Selected local calendar day as UTC midnight (`2026-06-02T00:00:00.000Z`).
  ///
  /// Avoids sending local midnight, which .NET often stores as the previous UTC
  /// day (`2026-06-01T22:00:00` for Libya UTC+2).
  static String formatForApi(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).toIso8601String();
  }

  /// Parses API values into the user's local calendar date (midnight).
  static DateTime parseFromApi(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.now();
    }

    final trimmed = raw.trim();

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      final parts = trimmed.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      return DateTime.now();
    }

    // Naive .NET JSON datetimes are UTC; `Z` / offset strings use their instant.
    final DateTime utcInstant;
    if (parsed.isUtc) {
      utcInstant = parsed;
    } else if (trimmed.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(trimmed)) {
      utcInstant = parsed.toUtc();
    } else {
      utcInstant = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }

    final local = utcInstant.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
