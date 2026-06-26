import 'dart:io';

import '../../../../core/utils/either.dart';
import '../../../../core/error/failures.dart';
import '../repositories/wallet_repository.dart';

class UploadReceiptImageUseCase {
  UploadReceiptImageUseCase(this._repository);

  final WalletRepository _repository;

  Future<Either<Failure, String>> call(File file) =>
      _repository.uploadReceiptImage(file);
}
