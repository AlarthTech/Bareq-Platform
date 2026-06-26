import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/legal_document.dart';
import '../entities/legal_document_type.dart';

abstract class LegalRepository {
  Future<Either<Failure, LegalDocument>> getDocument({
    required LegalDocumentType type,
    required String languageCode,
  });
}
