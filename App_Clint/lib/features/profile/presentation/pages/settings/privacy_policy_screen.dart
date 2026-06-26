import 'package:flutter/material.dart';

import '../../../../legal/domain/entities/legal_document_type.dart';
import '../../../../legal/presentation/pages/legal_document_page.dart';
import '../../../../legal/presentation/registration_legal_read_tracker.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final RegistrationLegalReadTracker? registrationReadTracker;

  const PrivacyPolicyScreen({
    super.key,
    this.registrationReadTracker,
  });

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(
      documentType: LegalDocumentType.privacy,
      registrationReadTracker: registrationReadTracker,
    );
  }
}
