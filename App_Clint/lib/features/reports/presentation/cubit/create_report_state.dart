import 'package:equatable/equatable.dart';

import '../../domain/entities/report.dart';

abstract class CreateReportState extends Equatable {
  const CreateReportState();

  @override
  List<Object?> get props => [];
}

class CreateReportInitial extends CreateReportState {
  const CreateReportInitial();
}

class CreateReportLoading extends CreateReportState {
  const CreateReportLoading();
}

class CreateReportSuccess extends CreateReportState {
  const CreateReportSuccess(this.report);

  final Report report;

  @override
  List<Object?> get props => [report];
}

class CreateReportError extends CreateReportState {
  const CreateReportError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
