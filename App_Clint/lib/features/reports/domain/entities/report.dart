import 'package:equatable/equatable.dart';

enum ReportTargetType {
  worker,
  company;

  int get apiValue => switch (this) {
        ReportTargetType.worker => 1,
        ReportTargetType.company => 2,
      };

  static ReportTargetType fromApi(int value) => switch (value) {
        1 => ReportTargetType.worker,
        2 => ReportTargetType.company,
        _ => ReportTargetType.worker,
      };
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed;

  static ReportStatus fromApi(int value) => switch (value) {
        0 => ReportStatus.pending,
        1 => ReportStatus.underReview,
        2 => ReportStatus.resolved,
        3 => ReportStatus.dismissed,
        _ => ReportStatus.pending,
      };
}

/// Customer report entity — [adminNotes] is never exposed to UI.
class Report extends Equatable {
  const Report({
    required this.id,
    required this.userId,
    this.userName,
    required this.targetType,
    this.targetTypeName,
    this.workerId,
    this.workerName,
    this.companyId,
    this.companyName,
    required this.description,
    required this.status,
    required this.statusName,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String? userName;
  final ReportTargetType targetType;
  final String? targetTypeName;
  final int? workerId;
  final String? workerName;
  final int? companyId;
  final String? companyName;
  final String description;
  final ReportStatus status;
  final String statusName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get targetDisplayName {
    if (targetType == ReportTargetType.worker) {
      return workerName ?? targetTypeName ?? '';
    }
    return companyName ?? targetTypeName ?? '';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        targetType,
        targetTypeName,
        workerId,
        workerName,
        companyId,
        companyName,
        description,
        status,
        statusName,
        createdAt,
        updatedAt,
      ];
}
