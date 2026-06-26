/// Parses work-type shift times and formats duration for display.
class ShiftHoursFormatter {
  ShiftHoursFormatter._();

  /// Total hours between [startTime] and [endTime] (e.g. "08:00", "18:00").
  /// Overnight shifts where end is before start add 24h to the end.
  static double? durationHours(String startTime, String endTime) {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    if (start == null || end == null) return null;

    var startMinutes = start.hour * 60 + start.minute;
    var endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }
    return (endMinutes - startMinutes) / 60.0;
  }

  /// e.g. "10 hours" / "10.5 hours" — pass localized [hoursLabel].
  static String? formatDurationLabel(
    String startTime,
    String endTime, {
    required String hoursLabel,
  }) {
    final hours = durationHours(startTime, endTime);
    if (hours == null) return null;
    final display =
        hours == hours.roundToDouble()
            ? hours.toInt().toString()
            : hours.toStringAsFixed(1);
    return '$display $hoursLabel';
  }

  static ({int hour, int minute})? _parseTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
    ).firstMatch(trimmed);
    if (match != null) {
      return (
        hour: int.parse(match.group(1)!),
        minute: int.parse(match.group(2)!),
      );
    }

    try {
      final dt = DateTime.parse(trimmed);
      return (hour: dt.hour, minute: dt.minute);
    } catch (_) {
      return null;
    }
  }
}
