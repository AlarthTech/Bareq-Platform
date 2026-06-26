import '../../domain/entities/report.dart';

class ReportModel {
  ReportModel({
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
  final int targetType;
  final String? targetTypeName;
  final int? workerId;
  final String? workerName;
  final int? companyId;
  final String? companyName;
  final String description;
  final int status;
  final String statusName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['userId']) ?? 0,
      userName: json['userName']?.toString(),
      targetType: _parseInt(json['targetType']) ?? 1,
      targetTypeName: json['targetTypeName']?.toString(),
      workerId: _parseInt(json['workerId']),
      workerName: json['workerName']?.toString(),
      companyId: _parseInt(json['companyId']),
      companyName: json['companyName']?.toString(),
      description: json['description']?.toString() ?? '',
      status: _parseInt(json['status']) ?? 0,
      statusName: json['statusName']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Report toEntity() {
    return Report(
      id: id,
      userId: userId,
      userName: userName,
      targetType: ReportTargetType.fromApi(targetType),
      targetTypeName: targetTypeName,
      workerId: workerId,
      workerName: workerName,
      companyId: companyId,
      companyName: companyName,
      description: description,
      status: ReportStatus.fromApi(status),
      statusName: statusName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
