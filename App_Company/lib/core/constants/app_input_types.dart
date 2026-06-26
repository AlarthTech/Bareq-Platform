import 'package:flutter/services.dart';

/// Shared text-field keyboard and formatter presets.
class AppInputTypes {
  AppInputTypes._();

  /// Integer numeric keyboard (type 1): digits only, no decimal or minus sign.
  static const TextInputType numberType1 = TextInputType.numberWithOptions(
    decimal: false,
    signed: false,
  );

  static final List<TextInputFormatter> digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];
}
