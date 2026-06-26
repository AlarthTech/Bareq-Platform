import 'package:equatable/equatable.dart';

import '../parsers/paged_list_parser.dart';

/// CleaningHouse paginated list envelope (data layer).
/// `{ items, page, pageSize, totalCount, totalPages, hasNextPage, hasPreviousPage }`
class PagedResult<T> extends Equatable {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PagedResult({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.totalPages = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
  });

  static PagedResult<T> empty<T>() => PagedResult<T>(items: const []);

  static PagedResult<T> fromJson<T>(
    dynamic data,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final rawItems = extractPagedItems(data);
    final meta = extractPagedMeta(data);
    final items = rawItems
        .map((e) => itemFromJson(Map<String, dynamic>.from(e)))
        .toList();
    return PagedResult<T>(
      items: items,
      page: meta.page,
      pageSize: meta.pageSize,
      totalCount: meta.totalCount,
      totalPages: meta.totalPages,
      hasNextPage: meta.hasNextPage,
      hasPreviousPage: meta.hasPreviousPage,
    );
  }

  static PagedResult<Map<String, dynamic>> fromJsonMaps(dynamic data) {
    return fromJson(data, (json) => json);
  }

  PagedResult<T> appendPage(PagedResult<T> next) {
    return PagedResult<T>(
      items: [...items, ...next.items],
      page: next.page,
      pageSize: next.pageSize,
      totalCount: next.totalCount,
      totalPages: next.totalPages,
      hasNextPage: next.hasNextPage,
      hasPreviousPage: next.hasPreviousPage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        page,
        pageSize,
        totalCount,
        totalPages,
        hasNextPage,
        hasPreviousPage,
      ];
}
