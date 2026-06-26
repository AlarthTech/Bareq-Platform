import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_section.dart';

class LegalDocumentModel {
  final String title;
  final String? intro;
  final String lastUpdated;
  final List<LegalDocumentSection> sections;
  final String? acceptance;

  const LegalDocumentModel({
    required this.title,
    this.intro,
    required this.lastUpdated,
    required this.sections,
    this.acceptance,
  });

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>? ?? [];
    return LegalDocumentModel(
      title: json['title'] as String? ?? '',
      intro: json['intro'] as String?,
      lastUpdated: json['lastUpdated'] as String? ?? '',
      acceptance: json['acceptance'] as String?,
      sections: sectionsJson
          .map((e) => LegalDocumentSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  LegalDocument toEntity() {
    return LegalDocument(
      title: title,
      intro: intro,
      lastUpdated: lastUpdated,
      sections: sections,
      acceptance: acceptance,
    );
  }
}

class LegalDocumentSectionModel {
  static LegalDocumentSection fromJson(Map<String, dynamic> json) {
    return LegalDocumentSection(
      title: json['title'] as String? ?? '',
      paragraphs: (json['paragraphs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bullets: (json['bullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
