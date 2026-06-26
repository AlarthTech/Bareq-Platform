import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/create_booking_report_usecase.dart';
import '../models/create_booking_report_args.dart';
import 'create_booking_report_state.dart';

class CreateBookingReportCubit extends Cubit<CreateBookingReportState> {
  CreateBookingReportCubit({
    required CreateBookingReportUseCase createBookingReportUseCase,
    required CreateBookingReportArgs args,
  })  : _createBookingReportUseCase = createBookingReportUseCase,
        _args = args,
        super(const CreateBookingReportInitial());

  final CreateBookingReportUseCase _createBookingReportUseCase;
  final CreateBookingReportArgs _args;

  int get bookingId => _args.bookingId;
  String get bookingLabel => _args.bookingLabel;
  int get bookingStatus => _args.bookingStatus;

  Future<void> submit({
    required String reason,
    String? description,
  }) async {
    if (isClosed || state is CreateBookingReportLoading) return;
    emit(const CreateBookingReportLoading());

    final result = await _createBookingReportUseCase(
      bookingId: _args.bookingId,
      reason: reason,
      description: description,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(CreateBookingReportError(_mapFailure(failure))),
      (report) => emit(CreateBookingReportSuccess(report)),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ValidationFailure) return failure.message;
    if (failure is ServerFailure) return failure.message;
    if (failure is AuthFailure) return failure.message;
    if (failure is ForbiddenFailure) return failure.message;
    if (failure is NetworkFailure) {
      return 'خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }
    return failure.message;
  }
}
