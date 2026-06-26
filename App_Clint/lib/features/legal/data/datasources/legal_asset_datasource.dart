import 'dart:convert';

import 'package:flutter/services.dart';

abstract class LegalAssetDataSource {
  Future<Map<String, dynamic>> loadLanguageBundle(String languageCode);
}

class LegalAssetDataSourceImpl implements LegalAssetDataSource {
  static const _termsKey = 'terms';
  static const _privacyKey = 'privacy';

  @override
  Future<Map<String, dynamic>> loadLanguageBundle(String languageCode) async {
    final normalized = languageCode.toLowerCase().startsWith('ar') ? 'ar' : 'en';
    final path = 'assets/legal/$normalized.json';
    final raw = await rootBundle.loadString(path);
    return json.decode(raw) as Map<String, dynamic>;
  }

  static String documentKeyFor(String type) {
    switch (type) {
      case _privacyKey:
        return _privacyKey;
      default:
        return _termsKey;
    }
  }
}
