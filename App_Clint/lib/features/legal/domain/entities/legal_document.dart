import 'package:equatable/equatable.dart';
import 'legal_document_section.dart';

class LegalDocument extends Equatable {
  final String title;
  final String? intro;
  final String lastUpdated;
  final List<LegalDocumentSection> sections;
  final String? acceptance;

  const LegalDocument({
    required this.title,
    this.intro,
    required this.lastUpdated,
    required this.sections,
    this.acceptance,
  });

  @override
  List<Object?> get props => [title, intro, lastUpdated, sections, acceptance];
}
