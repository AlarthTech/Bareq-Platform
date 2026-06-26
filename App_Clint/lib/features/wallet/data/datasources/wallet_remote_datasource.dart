import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/wallet_testing_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../../../core/network/paged_result.dart';
import '../../../../core/network/pagination_constants.dart';
import '../../domain/constants/wallet_top_up_methods.dart';
import '../../domain/entities/wallet_top_up_request.dart';
import '../utils/wallet_error_parser.dart';
import '../utils/wallet_payment_url.dart';

abstract class WalletRemoteDataSource {
  Future<Map<String, dynamic>> getWalletSummary();

  Future<PagedResult<Map<String, dynamic>>> getTransactions({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  });

  Future<Map<String, dynamic>> getBankTransferAccount();

  Future<Map<String, dynamic>> startBankCardTopUp(double amount);

  /// Legacy bank card top-up (404 fallback for startBankCardTopUp only).
  Future<Map<String, dynamic>> createLegacyBankCardTopUp(double amount);

  /// Test-only instant credit — POST /api/v1/wallet/test/bank-card-charge.
  Future<Map<String, dynamic>> testInstantBankCardCharge(double amount);

  Future<Map<String, dynamic>> createBankTransferTopUp(
    WalletTopUpRequest request,
  );

  Future<Map<String, dynamic>> getTopUpById(int id);

  Future<String> uploadReceiptImage(File file);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  Failure _mapDio(DioException e) {
    if (e.response?.statusCode == 404 &&
        e.requestOptions.path.contains('bank-transfer-account')) {
      return const NoBankAccountConfiguredFailure();
    }
    final walletFailure = parseWalletFailureFromBody(e.response?.data);
    if (walletFailure != null) return walletFailure;
    return mapDioExceptionToFailure(e);
  }

  @override
  Future<Map<String, dynamic>> getWalletSummary() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.walletSummary);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<PagedResult<Map<String, dynamic>>> getTransactions({
    int page = PaginationConstants.defaultPage,
    int pageSize = PaginationConstants.defaultPageSize,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJsonMaps(response.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getBankTransferAccount() async {
    try {
      final response =
          await _dioClient.get(ApiEndpoints.walletBankTransferAccount);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> startBankCardTopUp(double amount) async {
    final bodyAmount = _amountForBankCardApi(amount);
    try {
      final response = await _dioClient.post(
        ApiEndpoints.walletBankCardTopUp,
        data: {'amount': bodyAmount},
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      // Legacy servers only — preferred route is POST /wallet/top-up/bank-card.
      if (e.response?.statusCode == 404) {
        return _startBankCardTopUpLegacy(amount);
      }
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// API expects a positive number, e.g. `{ "amount": 150 }`.
  static num _amountForBankCardApi(double amount) {
    if (amount <= 0) return amount;
    final rounded = double.parse(amount.toStringAsFixed(2));
    return rounded == rounded.roundToDouble() ? rounded.toInt() : rounded;
  }

  @override
  Future<Map<String, dynamic>> createLegacyBankCardTopUp(double amount) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.walletTopUp,
        data: {
          'requestedAmount': amount,
          'paymentMethod': WalletTopUpMethods.bankCard,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Fallback when dedicated bank-card route is not deployed yet.
  Future<Map<String, dynamic>> _startBankCardTopUpLegacy(double amount) async {
    final topUp = await createLegacyBankCardTopUp(amount);
    return {
      'topUpId': topUp['id'],
      'paymentUrl': pickWalletPaymentUrl(topUp) ?? '',
      'gatewayPaymentReference': topUp['gatewayPaymentReference'],
      'message': topUp['message'],
    };
  }

  @override
  Future<Map<String, dynamic>> testInstantBankCardCharge(double amount) async {
    final headers = <String, String>{};
    final secret = WalletTestingConstants.testInstantTopUpSecret.trim();
    if (secret.isNotEmpty) {
      headers['X-Wallet-Test-Secret'] = secret;
    }
    try {
      final response = await _dioClient.post(
        ApiEndpoints.walletTestBankCardCharge,
        data: {'amount': _amountForBankCardApi(amount)},
        options: headers.isEmpty ? null : Options(headers: headers),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> createBankTransferTopUp(
    WalletTopUpRequest request,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.walletTopUp,
        data: request.toJson(),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getTopUpById(int id) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.walletTopUpStatus(id),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final response = await _dioClient.get(
            ApiEndpoints.walletTopUpById(id),
          );
          return _asMap(response.data);
        } on DioException catch (legacy) {
          throw _mapDio(legacy);
        }
      }
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadReceiptImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final response = await _dioClient.post(
        ApiEndpoints.uploadFile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        for (final key in [
          'url',
          'path',
          'fileUrl',
          'filePath',
          'transferReceiptImageUrl',
        ]) {
          final value = map[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
      if (data is String && data.trim().isNotEmpty) return data.trim();
      throw const ServerFailure('Invalid upload response');
    } on DioException catch (e) {
      throw _mapDio(e);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ServerFailure('Invalid response format');
  }
}
