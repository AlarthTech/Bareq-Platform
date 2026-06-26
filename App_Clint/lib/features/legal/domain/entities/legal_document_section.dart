import 'package:equatable/equatable.dart';

class LegalDocumentSection extends Equatable {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const LegalDocumentSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  @override
  List<Object?> get props => [title, paragraphs, bullets];
}
