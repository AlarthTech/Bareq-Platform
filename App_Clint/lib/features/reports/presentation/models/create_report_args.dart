import '../../domain/entities/report.dart';

/// Navigation args for [CreateReportPage].
class CreateReportArgs {
  const CreateReportArgs({
    required this.targetType,
    required this.targetId,
    required this.targetName,
    this.returnRoute,
  });

  final ReportTargetType targetType;
  final int targetId;
  final String targetName;

  /// Screen to return to when leaving reports (e.g. worker/company details).
  final String? returnRoute;
}
