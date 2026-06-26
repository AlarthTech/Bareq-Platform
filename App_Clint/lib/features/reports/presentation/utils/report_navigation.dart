import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/report.dart';

/// Pops when possible; otherwise navigates to [returnRoute] or home.
void popOrGoToReturnRoute(BuildContext context, {String? returnRoute}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  final route = returnRoute?.trim();
  if (route != null && route.isNotEmpty) {
    context.go(route);
    return;
  }
  context.go(AppStrings.routeHome);
}

String? returnRouteForReportTarget({
  required ReportTargetType targetType,
  required int targetId,
}) {
  if (targetId <= 0) return null;
  return switch (targetType) {
    ReportTargetType.worker => AppStrings.maidDetailsRoute(targetId.toString()),
    ReportTargetType.company =>
      AppStrings.companyDetailsRoute(targetId.toString()),
  };
}

String? returnRouteForReport(Report report) {
  final workerId = report.workerId;
  if (workerId != null && workerId > 0) {
    return AppStrings.maidDetailsRoute(workerId.toString());
  }
  final companyId = report.companyId;
  if (companyId != null && companyId > 0) {
    return AppStrings.companyDetailsRoute(companyId.toString());
  }
  return null;
}
