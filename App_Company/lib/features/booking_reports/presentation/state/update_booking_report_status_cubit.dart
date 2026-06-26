import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/booking_report_constants.dart';
import '../../domain/usecases/update_booking_report_status_usecase.dart';
import 'update_booking_report_status_state.dart';

class UpdateBookingReportStatusCubit extends Cubit<UpdateBookingReportStatusState> {
  UpdateBookingReportStatusCubit({
    required UpdateBookingReportStatusUseCase updateBookingReportStatusUseCase,
  })  : _updateBookingReportStatusUseCase = updateBookingReportStatusUseCase,
        super(const UpdateBookingReportStatusInitial());

  final UpdateBookingReportStatusUseCase _updateBookingReportStatusUseCase;

  Future<void> submit({
    required int reportId,
    required int status,
    String? adminResolutionNotes,
  }) async {
    if (BookingReportStatus.requiresNotes(status)) {
      final notes = adminResolutionNotes?.trim() ?? '';
      if (notes.isEmpty) {
        emit(
          const UpdateBookingReportStatusError(
            'ملاحظات الحل مطلوبة عند حل البلاغ أو رفضه',
          ),
        );
        emit(const UpdateBookingReportStatusInitial());
        return;
      }
      if (notes.length > 1000) {
        emit(
          const UpdateBookingReportStatusError(
            'ملاحظات الحل يجب ألا تتجاوز 1000 حرف',
          ),
        );
        emit(const UpdateBookingReportStatusInitial());
        return;
      }
    }

    emit(const UpdateBookingReportStatusLoading());

    final result = await _updateBookingReportStatusUseCase(
      UpdateBookingReportStatusParams(
        id: reportId,
        status: status,
        adminResolutionNotes: adminResolutionNotes,
      ),
    );

    result.fold(
      (failure) => emit(UpdateBookingReportStatusError(failure.message)),
      (report) => emit(UpdateBookingReportStatusSuccess(report)),
    );
  }

  void reset() => emit(const UpdateBookingReportStatusInitial());
}
