import 'dart:typed_data';

import '../entities/company_entity.dart';
import '../repositories/company_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class UploadCommercialRegisterUseCase {
  UploadCommercialRegisterUseCase(this.repository);

  final CompanyRepository repository;

  Future<Either<Failure, CompanyEntity>> call({
    required int companyId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) {
    return repository.uploadCommercialRegister(
      companyId: companyId,
      fileName: fileName,
      filePath: filePath,
      bytes: bytes,
    );
  }
}
