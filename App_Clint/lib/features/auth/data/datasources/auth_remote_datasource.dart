import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/social_auth_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/data/parsers/paged_list_parser.dart';
import '../../../../core/network/dio_failure_mapper.dart';

/// Remote data source for authentication
/// Handles all API calls related to auth
abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> registerCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int cityId,
  });

  Future<List<Map<String, dynamic>>> getAllCities();

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });

  Future<Map<String, dynamic>> socialLoginCustomer({
    required SocialAuthProvider provider,
    String? idToken,
    String? accessToken,
    String? fullName,
    String? phone,
  });

  Future<List<Map<String, dynamic>>> getAllAppUsers();

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Map<String, dynamic>> changePersonalInfo({
    required String fullName,
    required String email,
  });

  Future<Map<String, dynamic>> changePhoneNumber({
    required String phone,
    int? cityId,
  });

  Future<void> deleteAppUser(int id);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<Map<String, dynamic>> registerCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required int cityId,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.createCustomer,
        data: {
          'fullName': fullName,
          'phone': phone,
          'email': email,
          'password': password,
          'cityId': cityId,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage = _extractServerErrorMessage(e.response!) ?? 
            e.response!.statusMessage ??
            'Server error: $statusCode';
        throw ServerFailure(errorMessage, statusCode);
      }
      throw NetworkFailure(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllCities() async {
    try {
      final response = await dioClient.get(ApiEndpoints.getAllCities);
      return extractPagedItems(response.data);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  /// Extract error message from server response
  /// Shows the actual response text from the server
  String? _extractServerErrorMessage(Response response) {
    final data = response.data;
    
    // If response data is null, try to get response text directly
    if (data == null) {
      return null;
    }
    
    // If response data is a string, return it directly (most common case for plain text responses)
    if (data is String) {
      return data.trim().isNotEmpty ? data.trim() : null;
    }
    
    // If response data is a Map, try to extract error message
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map) {
        final parts = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            parts.add(value.first.toString());
          } else if (value != null) {
            parts.add(value.toString());
          }
        }
        if (parts.isNotEmpty) return parts.join('\n');
      }

      // Try common error message fields
      final message = data['message'] as String? ?? 
                     data['error'] as String? ??
                     data['Message'] as String? ??
                     data['ErrorMessage'] as String? ??
                     data['errorMessage'] as String? ??
                     data['title'] as String?;
      
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
      
      // If no message field, try to get the entire response as string
      return data.toString();
    }
    
    // If response data is a List, convert to readable string
    if (data is List) {
      if (data.isEmpty) return null;
      return data.map((item) => item.toString()).join(', ');
    }
    
    // Fallback: convert response data to string and trim
    final errorText = data.toString().trim();
    return errorText.isNotEmpty ? errorText : null;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
          'userType': 'Customer',
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (kDebugMode) {
        final status = e.response?.statusCode;
        final body = e.response?.data ?? e.message;
        debugPrint(
          'Login API error${status != null ? ' (HTTP $status)' : ''}: $body',
        );
      }
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage = _extractServerErrorMessage(e.response!) ?? 
            e.response!.statusMessage ??
            'Server error: $statusCode';
        throw ServerFailure(errorMessage, statusCode);
      }
      throw NetworkFailure(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> socialLoginCustomer({
    required SocialAuthProvider provider,
    String? idToken,
    String? accessToken,
    String? fullName,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        'provider': provider.apiValue,
      };
      if (idToken != null && idToken.trim().isNotEmpty) {
        body['idToken'] = idToken.trim();
      }
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        body['accessToken'] = accessToken.trim();
      }
      if (fullName != null && fullName.trim().isNotEmpty) {
        body['fullName'] = fullName.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        body['phone'] = phone.trim();
      }

      final response = await dioClient.post(
        ApiEndpoints.socialLoginCustomer,
        data: body,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data ?? e.message;
      debugPrint(
        'Social login API error${status != null ? ' (HTTP $status)' : ''}: $body',
      );
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage = _extractServerErrorMessage(e.response!) ??
            e.response!.statusMessage ??
            'Server error: $statusCode';
        throw ServerFailure(errorMessage, statusCode);
      }
      throw NetworkFailure(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllAppUsers() async {
    try {
      final response = await dioClient.get(ApiEndpoints.getAllAppUsers);

      if (response.data is List) {
        return (response.data as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorMessage = e.response!.statusMessage ??
            'Server error: $statusCode';
        throw ServerFailure(errorMessage, statusCode);
      }
      throw NetworkFailure(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await dioClient.put(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'message': data?.toString() ?? ''};
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> changePersonalInfo({
    required String fullName,
    required String email,
  }) async {
    try {
      final response = await dioClient.put(
        ApiEndpoints.changePersonalInfo,
        data: {'fullName': fullName, 'email': email},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> changePhoneNumber({
    required String phone,
    int? cityId,
  }) async {
    try {
      final data = <String, dynamic>{'phone': phone};
      if (cityId != null) {
        data['cityId'] = cityId;
      }
      final response = await dioClient.put(
        ApiEndpoints.changePhoneNumber,
        data: data,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAppUser(int id) async {
    try {
      await dioClient.delete(ApiEndpoints.deleteAppUser(id));
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Unexpected error: ${e.toString()}');
    }
  }
}

