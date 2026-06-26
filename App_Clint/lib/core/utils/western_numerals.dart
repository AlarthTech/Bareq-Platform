/// Converts Eastern Arabic-Indic and Persian digits to Western Arabic numerals (0–9).
class WesternNumerals {
  WesternNumerals._();

  static const _easternIndic = [
    '\u0660',
    '\u0661',
    '\u0662',
    '\u0663',
    '\u0664',
    '\u0665',
    '\u0666',
    '\u0667',
    '\u0668',
    '\u0669',
  ];
  static const _extendedArabicIndic = [
    '\u06F0',
    '\u06F1',
    '\u06F2',
    '\u06F3',
    '\u06F4',
    '\u06F5',
    '\u06F6',
    '\u06F7',
    '\u06F8',
    '\u06F9',
  ];
  static const _western = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  /// Returns [input] with all Eastern / Persian digit characters replaced by 0–9.
  static String normalize(String input) {
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(_easternIndic[i], _western[i]);
      result = result.replaceAll(_extendedArabicIndic[i], _western[i]);
    }
    return result;
  }
}
