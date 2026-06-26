import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/create_report_usecase.dart';
import '../models/create_report_args.dart';
import 'create_report_state.dart';

class CreateReportCubit extends Cubit<CreateReportState> {
  CreateReportCubit({
    required CreateReportUseCase createReportUseCase,
    required CreateReportArgs args,
  })  : _createReportUseCase = createReportUseCase,
        _args = args,
        super(const CreateReportInitial());

  final CreateReportUseCase _createReportUseCase;
  final CreateReportArgs _args;

  ReportTargetType get targetType => _args.targetType;
  String get targetName => _args.targetName;

  Future<void> submit(String description) async {
    if (isClosed || state is CreateReportLoading) return;
    emit(const CreateReportLoading());

    final result =
        _args.targetType == ReportTargetType.worker
            ? await _createReportUseCase.createWorkerReport(
              workerId: _args.targetId,
              description: description,
            )
            : await _createReportUseCase.createCompanyReport(
              companyId: _args.targetId,
              description: description,
            );

    if (isClosed) return;
    result.fold(
      (failure) => emit(CreateReportError(_mapFailure(failure))),
      (report) => emit(CreateReportSuccess(report)),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is ValidationFailure) return failure.message;
    if (failure is RateLimitFailure) return failure.message;
    if (failure is ForbiddenFailure) return failure.message;
    if (failure is AuthFailure) return failure.message;
    if (failure is ServerFailure) return failure.message;
    if (failure is NetworkFailure) {
      return 'خطأ في الشبكة. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }
    return failure.message;
  }
}
