import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_type.dart';
import '../../domain/repositories/legal_repository.dart';
import '../datasources/legal_asset_datasource.dart';
import '../models/legal_document_model.dart';

class LegalRepositoryImpl implements LegalRepository {
  final LegalAssetDataSource dataSource;

  LegalRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, LegalDocument>> getDocument({
    required LegalDocumentType type,
    required String languageCode,
  }) async {
    try {
      final bundle = await dataSource.loadLanguageBundle(languageCode);
      final key = type == LegalDocumentType.privacy ? 'privacy' : 'terms';
      final docJson = bundle[key];
      if (docJson is! Map<String, dynamic>) {
        return const Left(CacheFailure('Legal document not found'));
      }
      final model = LegalDocumentModel.fromJson(docJson);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load legal document: $e'));
    }
  }
}
