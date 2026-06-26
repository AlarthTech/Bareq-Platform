import 'package:flutter/foundation.dart';

/// Tracks whether the user has fully read Terms and Privacy during registration.
class RegistrationLegalReadTracker extends ChangeNotifier {
  bool termsFullyRead = false;
  bool privacyFullyRead = false;

  bool get canAgree => termsFullyRead && privacyFullyRead;

  void markTermsRead() {
    if (termsFullyRead) return;
    termsFullyRead = true;
    notifyListeners();
  }

  void markPrivacyRead() {
    if (privacyFullyRead) return;
    privacyFullyRead = true;
    notifyListeners();
  }

  bool isReadFor(LegalReadDocument document) {
    switch (document) {
      case LegalReadDocument.terms:
        return termsFullyRead;
      case LegalReadDocument.privacy:
        return privacyFullyRead;
    }
  }

  void markReadFor(LegalReadDocument document) {
    switch (document) {
      case LegalReadDocument.terms:
        markTermsRead();
      case LegalReadDocument.privacy:
        markPrivacyRead();
    }
  }
}

enum LegalReadDocument { terms, privacy }
