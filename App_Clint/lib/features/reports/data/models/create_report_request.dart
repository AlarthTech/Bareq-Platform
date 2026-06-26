import '../../domain/entities/report.dart';

class CreateWorkerReportRequest {
  CreateWorkerReportRequest({
    required this.workerId,
    required this.description,
    this.targetType = ReportTargetType.worker,
  });

  final int workerId;
  final String description;
  final ReportTargetType targetType;

  Map<String, dynamic> toJson() => {
        'targetType': targetType.apiValue,
        'workerId': workerId,
        'description': description.trim(),
      };
}

class CreateCompanyReportRequest {
  CreateCompanyReportRequest({
    required this.companyId,
    required this.description,
    this.targetType = ReportTargetType.company,
  });

  final int companyId;
  final String description;
  final ReportTargetType targetType;

  Map<String, dynamic> toJson() => {
        'targetType': targetType.apiValue,
        'companyId': companyId,
        'description': description.trim(),
      };
}
