import '../models/user_model.dart';
import '../models/login_response_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(String username, String password);
  Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    int? cityId,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<UserModel> changePersonalInfo({
    required String fullName,
    String? email,
  });
  Future<UserModel> changePhoneNumber(String phoneNumber);
  Future<void> deleteMyCompanyAccount(String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  
  AuthRemoteDataSourceImpl(this.apiClient);
  
  @override
  Future<LoginResponseModel> login(String username, String password) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
          'userType': 'Company',
        },
      );
      
      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('فشل تسجيل الدخول', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تسجيل الدخول'),
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  @override
  Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    int? cityId,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.register,
        data: {
          'fullName': fullName.trim(),
          'phone': phone.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          if (cityId != null) 'cityId': cityId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('فشل إنشاء الحساب', response.statusCode);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429) {
        throw const RateLimitException(
          'تجاوزت الحد المسموح من المحاولات. يرجى المحاولة بعد ساعة.',
        );
      }
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل إنشاء الحساب'),
        status,
      );
    } catch (e) {
      if (e is RateLimitException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.dio.put(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('فشل تغيير كلمة المرور', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تغيير كلمة المرور'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> changePersonalInfo({
    required String fullName,
    String? email,
  }) async {
    try {
      final response = await apiClient.dio.put(
        ApiConstants.changePersonalInfo,
        data: {
          'fullName': fullName,
          if (email != null) 'email': email,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return UserModel.fromJson(data);
        }
        return UserModel.fromJson({'fullName': fullName, 'email': email});
      }
      throw ServerException('فشل تحديث البيانات الشخصية', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديث البيانات الشخصية'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> changePhoneNumber(String phoneNumber) async {
    try {
      final response = await apiClient.dio.put(
        ApiConstants.changePhoneNumber,
        data: {'phone': phoneNumber},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return UserModel.fromJson(data);
        }
        return UserModel.fromJson({'phone': phoneNumber});
      }
      throw ServerException('فشل تغيير رقم الهاتف', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تغيير رقم الهاتف'),
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteMyCompanyAccount(String password) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.deleteMyCompanyAccount,
        data: {'password': password},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final status = response.statusCode;
      if (status == 204) return;

      final message = dioErrorMessage(
        response.data,
        'تعذر حذف الحساب.',
      );

      switch (status) {
        case 400:
          throw ValidationException(message);
        case 401:
          throw const UnauthorizedException(
            'غير مصرح لك. يرجى تسجيل الدخول مرة أخرى',
          );
        case 404:
          throw NotFoundException(message);
        case 409:
          throw ActiveBookingsException(
            message.isNotEmpty
                ? message
                : 'لا يمكن حذف الحساب لوجود حجوزات نشطة. يُرجى إكمالها أو إلغاؤها أولاً.',
          );
        case 429:
          throw const RateLimitException(
            'تجاوزت الحد المسموح من المحاولات. يرجى المحاولة لاحقاً.',
          );
        default:
          throw ServerException(message, status);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429) {
        throw const RateLimitException(
          'تجاوزت الحد المسموح من المحاولات. يرجى المحاولة لاحقاً.',
        );
      }
      throw ServerException(
        dioErrorMessage(e.response?.data, 'تعذر حذف الحساب.'),
        status,
      );
    }
  }
}
