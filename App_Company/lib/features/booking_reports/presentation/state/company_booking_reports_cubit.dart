import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/booking_report_constants.dart';
import '../../domain/entities/booking_report.dart';
import '../../domain/usecases/get_company_booking_reports_usecase.dart';
import 'company_booking_reports_state.dart';

class CompanyBookingReportsCubit extends Cubit<CompanyBookingReportsState> {
  CompanyBookingReportsCubit({
    required GetCompanyBookingReportsUseCase getCompanyBookingReportsUseCase,
  })  : _getCompanyBookingReportsUseCase = getCompanyBookingReportsUseCase,
        super(const CompanyBookingReportsInitial());

  final GetCompanyBookingReportsUseCase _getCompanyBookingReportsUseCase;

  static const _pageSize = 20;

  int? _bookingIdFilter;

  Future<void> load({
    int? statusFilter,
    int? bookingId,
    bool clearStatusFilter = false,
  }) async {
    if (bookingId != null) _bookingIdFilter = bookingId;

    final current = state;
    if (current is CompanyBookingReportsLoaded) {
      emit(
        current.copyWith(
          isRefreshing: true,
          statusFilter: clearStatusFilter ? null : statusFilter,
          clearStatusFilter: clearStatusFilter,
          bookingIdFilter: _bookingIdFilter,
        ),
      );
    } else {
      emit(const CompanyBookingReportsLoading());
    }

    final filters = BookingReportFilters(
      status: clearStatusFilter ? null : statusFilter,
      bookingId: _bookingIdFilter,
    );

    final result = await _getCompanyBookingReportsUseCase(
      GetCompanyBookingReportsParams(
        filters: filters,
        page: 1,
        pageSize: _pageSize,
      ),
    );

    result.fold(
      (failure) => emit(CompanyBookingReportsError(failure.message)),
      (page) async {
        int? openCount;
        if (_bookingIdFilter == null) {
          openCount = await _fetchOpenCount();
        }
        emit(
          CompanyBookingReportsLoaded(
            reports: page.items,
            hasNextPage: page.hasNextPage,
            page: page.page,
            statusFilter: clearStatusFilter ? null : statusFilter,
            bookingIdFilter: _bookingIdFilter,
            openReportsCount: openCount,
          ),
        );
      },
    );
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! CompanyBookingReportsLoaded) {
      await load(bookingId: _bookingIdFilter);
      return;
    }
    await load(
      statusFilter: current.statusFilter,
      bookingId: _bookingIdFilter,
    );
  }

  Future<void> setStatusFilter(int? status) async {
    await load(
      statusFilter: status,
      bookingId: _bookingIdFilter,
      clearStatusFilter: status == null,
    );
  }

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! CompanyBookingReportsLoaded ||
        !current.hasNextPage ||
        current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    final filters = BookingReportFilters(
      status: current.statusFilter,
      bookingId: current.bookingIdFilter,
    );

    final result = await _getCompanyBookingReportsUseCase(
      GetCompanyBookingReportsParams(
        filters: filters,
        page: current.page + 1,
        pageSize: _pageSize,
      ),
    );

    result.fold(
      (failure) => emit(CompanyBookingReportsError(failure.message)),
      (page) => emit(
        current.copyWith(
          reports: [...current.reports, ...page.items],
          hasNextPage: page.hasNextPage,
          page: page.page,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<int?> _fetchOpenCount() async {
    final result = await _getCompanyBookingReportsUseCase(
      const GetCompanyBookingReportsParams(
        filters: BookingReportFilters(status: BookingReportStatus.open),
        page: 1,
        pageSize: 1,
      ),
    );
    return result.fold((_) => null, (page) => page.totalCount);
  }
}
