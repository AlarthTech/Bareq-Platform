import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd', 'ar');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'ar');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm', 'ar');
  static final DateFormat _displayDateFormat = DateFormat('d MMMM yyyy', 'ar');
  static final DateFormat _displayWeekdayDateFormat =
      DateFormat('EEEE d MMMM yyyy', 'ar');
  static final DateFormat _displayWeekdayCompactFormat =
      DateFormat('EEEE d MMMM', 'ar');
  static final DateFormat _displayTimeFormat = DateFormat('h:mm a', 'ar');

  /// Converts Eastern Arabic numerals (٠–٩) to Western digits (0–9).
  static String toLatinDigits(String value) {
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = value;
    for (var i = 0; i < eastern.length; i++) {
      result = result.replaceAll(eastern[i], western[i]);
    }
    return result;
  }

  static String formatDate(DateTime date) {
    return toLatinDigits(_dateFormat.format(date));
  }

  static String formatTime(DateTime time) {
    return toLatinDigits(_timeFormat.format(time));
  }

  static String formatDateTime(DateTime dateTime) {
    return toLatinDigits(_dateTimeFormat.format(dateTime));
  }

  static String formatDisplayDate(DateTime date) {
    return toLatinDigits(_displayDateFormat.format(date));
  }

  static String formatDisplayWeekdayDate(DateTime date) {
    return toLatinDigits(_displayWeekdayDateFormat.format(date));
  }

  static String formatDisplayWeekdayCompact(DateTime date) {
    return toLatinDigits(_displayWeekdayCompactFormat.format(date));
  }

  static String formatDisplayTime(DateTime time) {
    return toLatinDigits(_displayTimeFormat.format(time));
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'منذ لحظات';
    }
  }

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final now = DateTime.now();
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }
}
