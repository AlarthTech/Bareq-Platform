import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Helper class to easily access localized strings
/// Usage: L10n.of(context).translate('key')
class L10n {
  static AppLocalizations? of(BuildContext context) {
    return AppLocalizations.of(context);
  }

  static String translate(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context);
    return localizations?.translate(key) ?? key;
  }
}






