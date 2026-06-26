import '../models/worker_model.dart';
import '../models/nationality_model.dart';
import '../models/language_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/data/parsers/paged_response_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';

abstract class WorkerRemoteDataSource {
  Future<PagedResult<WorkerModel>> getWorkersByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  });
  Future<WorkerModel> createWorker({
    required int companyId,
    required String fullName,
    required int nationalityId,
    required int age,
    required int experienceYears,
    required bool isAvailable,
    required bool isActive,
    String? profileImage,
    String? healthCertificate,
    DateTime? healthCertificateExpiryDate,
    required String languagesIds,
  });
  Future<List<NationalityModel>> getNationalities();
  Future<List<LanguageModel>> getAllLanguages();
  Future<WorkerModel> uploadHealthCertificate({
    required int workerId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  });
  Future<void> updateWorker({
    required int workerId,
    required String fullName,
    required int nationalityId,
    required int age,
    required int experienceYears,
    String? healthCertificateURL,
    DateTime? healthCertificateExpiryDate,
    required String languagesIds,
  });
}

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  final ApiClient apiClient;
  
  WorkerRemoteDataSourceImpl(this.apiClient);
  
  @override
  Future<PagedResult<WorkerModel>> getWorkersByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  }) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.getWorkersByCompany}/$companyId',
        queryParameters: pagination.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        return parsePagedResponse(
          response.data,
          (json) => WorkerModel.fromJson(json),
        );
      }
      throw ServerException('فشل جلب قائمة العاملات', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب قائمة العاملات'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  @override
  Future<WorkerModel> createWorker({
    required int companyId,
    required String fullName,
    required int nationalityId,
    required int age,
    required int experienceYears,
    required bool isAvailable,
    required bool isActive,
    String? profileImage,
    String? healthCertificate,
    DateTime? healthCertificateExpiryDate,
    required String languagesIds,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.createWorker,
        data: {
          'companyId': companyId,
          'fullName': fullName,
          'nationalityId': nationalityId,
          'age': age,
          'experienceYears': experienceYears,
          'isAvailable': isAvailable,
          'isActive': isActive,
          'profileImage': profileImage,
          'healthCertificate': healthCertificate,
          'healthCertificateExpiryDate': healthCertificateExpiryDate?.toIso8601String(),
          'languagesIds': languagesIds,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return WorkerModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('فشل إنشاء العاملة', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] as String? ?? 'فشل إنشاء العاملة',
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  @override
  Future<List<NationalityModel>> getNationalities() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.getNationalities);
      
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => NationalityModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerException('فشل جلب قائمة الجنسيات', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] as String? ?? 'فشل جلب قائمة الجنسيات',
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  @override
  Future<List<LanguageModel>> getAllLanguages() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.getAllLanguages);
      
      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => LanguageModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerException('فشل جلب قائمة اللغات', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] as String? ?? 'فشل جلب قائمة اللغات',
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<void> updateWorker({
    required int workerId,
    required String fullName,
    required int nationalityId,
    required int age,
    required int experienceYears,
    String? healthCertificateURL,
    DateTime? healthCertificateExpiryDate,
    required String languagesIds,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        ApiConstants.updateWorker(workerId),
        data: {
          'fullName': fullName.trim(),
          'nationalityId': nationalityId,
          'age': age,
          'experienceYears': experienceYears,
          'healthCertificateURL': healthCertificateURL,
          'healthCertificateExpiryDate':
              healthCertificateExpiryDate?.toIso8601String(),
          'languagesIds': languagesIds,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw ServerException('فشل تحديث بيانات العاملة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديث بيانات العاملة'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<WorkerModel> uploadHealthCertificate({
    required int workerId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    try {
      final MultipartFile filePart;
      if (filePath != null) {
        filePart = await MultipartFile.fromFile(filePath, filename: fileName);
      } else if (bytes != null) {
        filePart = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        throw const ServerException('ملف غير صالح');
      }

      final response = await apiClient.dio.post(
        ApiConstants.uploadHealthCertificate(workerId),
        data: FormData.fromMap({'file': filePart}),
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: ApiConstants.longRunningReceiveTimeout,
          sendTimeout: ApiConstants.longRunningSendTimeout,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return WorkerModel.fromJson(data);
        }
        if (data is Map) {
          return WorkerModel.fromJson(Map<String, dynamic>.from(data));
        }
        if (data is String && data.trim().isNotEmpty) {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            return WorkerModel.fromJson(decoded);
          }
          if (decoded is Map) {
            return WorkerModel.fromJson(Map<String, dynamic>.from(decoded));
          }
        }
        throw const ServerException('استجابة رفع الشهادة الصحية غير صالحة');
      }
      throw ServerException('فشل رفع الشهادة الصحية', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل رفع الشهادة الصحية'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
}
