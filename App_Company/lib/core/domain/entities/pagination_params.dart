import 'package:equatable/equatable.dart';
import '../../constants/app_constants.dart';

class PaginationParams extends Equatable {
  final int page;
  final int pageSize;

  const PaginationParams({
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
  });

  Map<String, dynamic> toQueryParameters() => {
        'page': page,
        'pageSize': pageSize,
      };

  @override
  List<Object> get props => [page, pageSize];
}
