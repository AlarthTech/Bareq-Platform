import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_report.dart';
import '../../domain/usecases/get_booking_report_by_id_usecase.dart';
import 'booking_report_detail_state.dart';

class BookingReportDetailCubit extends Cubit<BookingReportDetailState> {
  BookingReportDetailCubit({
    required GetBookingReportByIdUseCase getBookingReportByIdUseCase,
  })  : _getBookingReportByIdUseCase = getBookingReportByIdUseCase,
        super(const BookingReportDetailInitial());

  final GetBookingReportByIdUseCase _getBookingReportByIdUseCase;

  Future<void> load(int reportId) async {
    emit(const BookingReportDetailLoading());

    final result = await _getBookingReportByIdUseCase(reportId);
    result.fold(
      (failure) => emit(BookingReportDetailError(failure.message)),
      (report) => emit(BookingReportDetailLoaded(report)),
    );
  }

  void applyReport(BookingReport report) {
    emit(BookingReportDetailLoaded(report));
  }
}
