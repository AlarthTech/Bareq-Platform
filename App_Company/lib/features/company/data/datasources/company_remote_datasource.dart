import 'dart:convert';
import 'dart:typed_data';

import '../models/company_model.dart';
import '../models/city_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/data/parsers/paged_response_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class CompanyRemoteDataSource {
  Future<List<CompanyModel>> getMyCompany(int userId);
  Future<CompanyModel> createCompany({
    required String name,
    String? address,
    String? commercialRegNo,
    required String phone,
    required String email,
    required int ownerUserId,
    required int cityId,
    int experienceYears,
    String? description,
  });
  Future<CompanyModel> uploadCommercialRegister({
    required int companyId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  });
  Future<CompanyModel> updateCompany({
    required int companyId,
    required String name,
    String? address,
    String? commercialRegNo,
    String? commercialRegisterURL,
    required String email,
    required int cityId,
    int experienceYears,
    String? description,
  });
  Future<List<CityModel>> getAllCities({int page = 1, int pageSize = 50});
}

class CompanyRemoteDataSourceImpl implements CompanyRemoteDataSource {
  CompanyRemoteDataSourceImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<CompanyModel>> getMyCompany(int userId) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.getMyCompany}/$userId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map((json) => CompanyModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (data is Map<String, dynamic>) {
          return [CompanyModel.fromJson(data)];
        }
        return [];
      } else {
        throw ServerException('فشل جلب بيانات الشركة', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب بيانات الشركة'),
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<CompanyModel> createCompany({
    required String name,
    String? address,
    String? commercialRegNo,
    required String phone,
    required String email,
    required int ownerUserId,
    required int cityId,
    int experienceYears = 0,
    String? description,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.createCompany,
        data: {
          'name': name.trim(),
          'address': address?.trim() ?? '',
          'commercialRegNo': commercialRegNo?.trim() ?? '',
          'phone': phone.trim(),
          'email': email.trim(),
          'ownerUserId': ownerUserId,
          'cityId': cityId,
          'experienceYears': experienceYears,
          'description': description?.trim() ?? '',
        },
        options: Options(
          receiveTimeout: ApiConstants.longRunningReceiveTimeout,
          sendTimeout: ApiConstants.longRunningSendTimeout,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CompanyModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('فشل إنشاء الشركة', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل إنشاء الشركة'),
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<CompanyModel> uploadCommercialRegister({
    required int companyId,
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    final MultipartFile filePart;
    if (filePath != null) {
      filePart = await MultipartFile.fromFile(filePath, filename: fileName);
    } else if (bytes != null) {
      filePart = MultipartFile.fromBytes(bytes, filename: fileName);
    } else {
      throw const ServerException('ملف غير صالح');
    }

    const maxAttempts = 3;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await apiClient.dio.post(
          ApiConstants.uploadCommercialRegister(companyId),
          data: FormData.fromMap({'file': filePart}),
          options: Options(
            receiveTimeout: ApiConstants.longRunningReceiveTimeout,
            sendTimeout: ApiConstants.longRunningSendTimeout,
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            return CompanyModel.fromJson(data);
          }
          if (data is Map) {
            return CompanyModel.fromJson(Map<String, dynamic>.from(data));
          }
          if (data is String && data.trim().isNotEmpty) {
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic>) {
              return CompanyModel.fromJson(decoded);
            }
            if (decoded is Map) {
              return CompanyModel.fromJson(Map<String, dynamic>.from(decoded));
            }
          }
          throw const ServerException('استجابة رفع السجل التجاري غير صالحة');
        }
        throw ServerException('فشل رفع السجل التجاري', response.statusCode);
      } on DioException catch (e) {
        lastError = e;
        final canRetry = attempt < maxAttempts &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout);
        if (canRetry) {
          await Future<void>.delayed(Duration(seconds: attempt));
          continue;
        }
        throw ServerException(
          dioUploadErrorMessage(e, 'فشل رفع السجل التجاري'),
          e.response?.statusCode,
        );
      } catch (e) {
        if (e is ServerException) rethrow;
        lastError = e;
        throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
      }
    }

    if (lastError is DioException) {
      throw ServerException(
        dioUploadErrorMessage(lastError, 'فشل رفع السجل التجاري'),
        lastError.response?.statusCode,
      );
    }
    throw ServerException('فشل رفع السجل التجاري');
  }

  @override
  Future<CompanyModel> updateCompany({
    required int companyId,
    required String name,
    String? address,
    String? commercialRegNo,
    String? commercialRegisterURL,
    required String email,
    required int cityId,
    int experienceYears = 0,
    String? description,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        ApiConstants.updateCompany(companyId),
        data: {
          'name': name.trim(),
          'address': address?.trim() ?? '',
          'commercialRegNo': commercialRegNo?.trim() ?? '',
          'commercialRegisterURL': commercialRegisterURL?.trim() ?? '',
          'email': email.trim(),
          'cityId': cityId,
          'experienceYears': experienceYears,
          'description': description?.trim() ?? '',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return CompanyModel.fromJson(data);
        }
        if (data is Map) {
          return CompanyModel.fromJson(Map<String, dynamic>.from(data));
        }
        if (response.statusCode == 204) {
          return CompanyModel(
            id: companyId,
            name: name.trim(),
            address: address?.trim() ?? '',
            commercialRegNo: commercialRegNo?.trim() ?? '',
            commercialRegisterUrl: commercialRegisterURL?.trim(),
            phone: '',
            email: email.trim(),
            ownerUserId: 0,
            cityId: cityId,
            experienceYears: experienceYears,
            description: description?.trim() ?? '',
          );
        }
        throw const ServerException('تنسيق استجابة تحديث الشركة غير متوقع');
      }
      throw ServerException('فشل تحديث الشركة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديث الشركة'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<List<CityModel>> getAllCities({int page = 1, int pageSize = 50}) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.getAllCities,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.statusCode == 200) {
        final paged = parsePagedResponse<CityModel>(
          response.data,
          CityModel.fromJson,
        );
        return paged.items.where((city) => city.isActive).toList();
      } else {
        throw ServerException('فشل جلب قائمة المدن', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب قائمة المدن'),
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
}
