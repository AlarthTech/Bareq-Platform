import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

/// Language provider to manage app language state
/// Singleton pattern for global access
class LanguageProvider extends ChangeNotifier {
  static LanguageProvider? _instance;
  static LanguageProvider get instance {
    _instance ??= LanguageProvider._();
    return _instance!;
  }

  LanguageProvider._() {
    _loadSavedLanguage();
  }

  Locale _locale = AppLocalizations.defaultLocale;
  
  Locale get locale => _locale;
  
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'ar';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      // If loading fails, use default
      _locale = AppLocalizations.defaultLocale;
    }
  }

  Future<void> setLanguage(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      // If saving fails, continue anyway
    }
  }

  Future<void> toggleLanguage() async {
    final newLocale = isArabic 
        ? const Locale('en', '')
        : const Locale('ar', '');
    await setLanguage(newLocale);
  }
}

