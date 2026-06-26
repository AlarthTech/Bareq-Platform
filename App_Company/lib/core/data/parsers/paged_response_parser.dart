import '../../domain/entities/paged_result.dart';
import '../../error/exceptions.dart';

PagedResult<T> parsePagedResponse<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) itemFromJson,
) {
  if (data is! Map<String, dynamic>) {
    throw const ServerException('تنسيق الاستجابة غير صالح — يتوقّر كائن صفحات');
  }

  final rawItems = data['items'];
  if (rawItems is! List) {
    throw const ServerException('تنسيق الاستجابة غير صالح — حقل items مفقود');
  }

  final items = rawItems
      .map((e) => itemFromJson(e as Map<String, dynamic>))
      .toList(growable: false);

  final page = _asInt(data['page'], fallback: 1);
  final pageSize = _asInt(data['pageSize'], fallback: items.length);
  final totalCount = _asInt(data['totalCount'], fallback: items.length);
  final totalPages = _asInt(data['totalPages'], fallback: 1);

  return PagedResult<T>(
    items: items,
    page: page,
    pageSize: pageSize,
    totalCount: totalCount,
    totalPages: totalPages,
    hasNextPage: data['hasNextPage'] as bool? ?? page < totalPages,
    hasPreviousPage: data['hasPreviousPage'] as bool? ?? page > 1,
  );
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Some endpoints return a bare JSON array; others return [PagedResult] shape.
PagedResult<T> parseListOrPagedResponse<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) itemFromJson,
) {
  if (data is List) {
    final items = data
        .map((e) => itemFromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return PagedResult<T>(
      items: items,
      page: 1,
      pageSize: items.isEmpty ? 1 : items.length,
      totalCount: items.length,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
  return parsePagedResponse(data, itemFromJson);
}
