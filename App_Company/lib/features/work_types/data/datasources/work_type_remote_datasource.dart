import '../models/work_type_request.dart';
import '../models/work_type_model.dart';
import '../models/worker_work_type_assignment_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/domain/entities/paged_result.dart';
import '../../../../core/domain/entities/pagination_params.dart';
import '../../../../core/data/parsers/paged_response_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class WorkTypeRemoteDataSource {
  Future<PagedResult<WorkTypeModel>> getWorkTypesByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  });
  Future<WorkTypeModel> getWorkTypeById(int workTypeId);
  Future<WorkTypeModel> createWorkType({
    required String name,
    required int companyId,
    required bool isMonthly,
    required double price,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  });
  Future<void> updateWorkType({
    required int workTypeId,
    required String name,
    required bool isMonthly,
    required double price,
    required bool isActive,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  });
  Future<void> deleteWorkType(int workTypeId);
  Future<void> assignWorkTypeToWorker({
    required int workerId,
    required int workTypeId,
  });
  Future<List<WorkerWorkTypeAssignmentModel>> getWorkerWorkTypes(int workerId);
}

class WorkTypeRemoteDataSourceImpl implements WorkTypeRemoteDataSource {
  final ApiClient apiClient;
  
  WorkTypeRemoteDataSourceImpl(this.apiClient);
  
  @override
  Future<PagedResult<WorkTypeModel>> getWorkTypesByCompany(
    int companyId, {
    PaginationParams pagination = const PaginationParams(),
  }) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.getWorkTypesByCompany}/$companyId',
        queryParameters: pagination.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        return parseListOrPagedResponse(
          response.data,
          (json) => WorkTypeModel.fromJson(json),
        );
      }
      throw ServerException('فشل جلب قائمة الخدمات', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل جلب قائمة الخدمات'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  @override
  Future<WorkTypeModel> getWorkTypeById(int workTypeId) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.getWorkTypeById}/$workTypeId',
      );
      
      if (response.statusCode == 200) {
        return WorkTypeModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('فشل جلب بيانات الخدمة', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] as String? ?? 'فشل جلب بيانات الخدمة',
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  @override
  Future<WorkTypeModel> createWorkType({
    required String name,
    required int companyId,
    required bool isMonthly,
    required double price,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.createWorkType,
        data: WorkTypeRequestBuilder.toCreateJson(
          companyId: companyId,
          name: name,
          isMonthly: isMonthly,
          price: price,
          startTime: startTime,
          endTime: endTime,
          isOvernight: isOvernight,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WorkTypeModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('فشل إنشاء الخدمة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل إنشاء الخدمة'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<void> updateWorkType({
    required int workTypeId,
    required String name,
    required bool isMonthly,
    required double price,
    required bool isActive,
    String? startTime,
    String? endTime,
    bool isOvernight = false,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        '${ApiConstants.updateWorkType}/$workTypeId',
        data: WorkTypeRequestBuilder.toUpdateJson(
          name: name,
          isMonthly: isMonthly,
          price: price,
          isActive: isActive,
          startTime: startTime,
          endTime: endTime,
          isOvernight: isOvernight,
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201) {
        return;
      }
      throw ServerException('فشل تحديث الخدمة', response.statusCode);
    } on DioException catch (e) {
      throw ServerException(
        dioErrorMessage(e.response?.data, 'فشل تحديث الخدمة'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteWorkType(int workTypeId) async {
    try {
      final response = await apiClient.dio.delete(
        '${ApiConstants.deleteWorkType}/$workTypeId',
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('فشل حذف الخدمة', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] as String? ?? 'فشل حذف الخدمة',
        e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<void> assignWorkTypeToWorker({
    required int workerId,
    required int workTypeId,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.assignWorkTypeToWorker,
        data: {
          'workerId': workerId,
          'workTypeId': workTypeId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw ServerException('فشل ربط الخدمة بالعاملة', response.statusCode);
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'فشل ربط الخدمة بالعاملة';
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      throw ServerException(msg, e.response?.statusCode);
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<List<WorkerWorkTypeAssignmentModel>> getWorkerWorkTypes(int workerId) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.getWorkerWorkTypes}/$workerId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data == null) return [];
        if (data is List) {
          return data
              .map(
                (e) => WorkerWorkTypeAssignmentModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        if (data is Map<String, dynamic>) {
          return [WorkerWorkTypeAssignmentModel.fromJson(data)];
        }
        return [];
      }
      throw ServerException('فشل جلب خدمات العاملة', response.statusCode);
    } on DioException catch (e) {
      final d = e.response?.data;
      String msg = 'فشل جلب خدمات العاملة';
      if (d is Map && d['message'] is String) {
        msg = d['message'] as String;
      } else if (d is String && d.isNotEmpty) {
        msg = d;
      }
      throw ServerException(msg, e.response?.statusCode);
    } catch (e) {
      throw ServerException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
}
