/// Formats and displays star ratings consistently across the app.
class RatingFormatter {
  RatingFormatter._();

  /// One decimal place, e.g. 4.8
  static String formatAverage(double rating) {
    return rating.toStringAsFixed(1);
  }
}
