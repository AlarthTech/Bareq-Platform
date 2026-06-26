import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/legal_document.dart';
import '../entities/legal_document_type.dart';
import '../repositories/legal_repository.dart';

class GetLegalDocumentUseCase {
  final LegalRepository repository;

  GetLegalDocumentUseCase(this.repository);

  Future<Either<Failure, LegalDocument>> call({
    required LegalDocumentType type,
    required String languageCode,
  }) {
    return repository.getDocument(type: type, languageCode: languageCode);
  }
}
