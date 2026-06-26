import '../pagination/pagination_constants.dart';

/// Parses list responses: raw arrays or CleaningHouse paginated envelopes.
List<Map<String, dynamic>> extractPagedItems(dynamic data) {
  if (data == null) return [];
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in [
      'items',
      'data',
      'result',
      'value',
      'bookings',
      'results',
      'workers',
      'companies',
      'userLocations',
      'locations',
    ]) {
      final v = map[key];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
  }
  return [];
}

class PagedMeta {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedMeta({
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.totalPages = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
  });
}

int _asInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic v, bool fallback) {
  if (v is bool) return v;
  if (v == 'true') return true;
  if (v == 'false') return false;
  return fallback;
}

PagedMeta extractPagedMeta(dynamic data) {
  if (data is! Map) {
    final items = extractPagedItems(data);
    return PagedMeta(
      page: 1,
      pageSize: items.length,
      totalCount: items.length,
      totalPages: items.isEmpty ? 0 : 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
  final map = Map<String, dynamic>.from(data);
  final items = extractPagedItems(data);
  final page = _asInt(map['page'], 1);
  final pageSize = _asInt(map['pageSize'], items.length);
  final totalCount = _asInt(map['totalCount'], items.length);
  final totalPages = _asInt(map['totalPages'], totalCount > 0 ? 1 : 0);
  final hasNext = map.containsKey('hasNextPage')
      ? _asBool(map['hasNextPage'], false)
      : page < totalPages;
  final hasPrev = map.containsKey('hasPreviousPage')
      ? _asBool(map['hasPreviousPage'], false)
      : page > 1;
  return PagedMeta(
    page: page,
    pageSize: pageSize,
    totalCount: totalCount,
    totalPages: totalPages,
    hasNextPage: hasNext,
    hasPreviousPage: hasPrev,
  );
}

Map<String, dynamic> paginationQuery({
  int page = PaginationConstants.defaultPage,
  int pageSize = PaginationConstants.defaultPageSize,
}) {
  final size = pageSize.clamp(1, PaginationConstants.maxPageSize);
  return {'page': page, 'pageSize': size};
}
