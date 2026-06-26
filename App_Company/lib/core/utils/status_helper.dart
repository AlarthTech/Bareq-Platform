import '../constants/app_constants.dart';

class StatusHelper {
  static String getStatusText(int status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppConstants.statusPendingText;
      case AppConstants.statusApproved:
        return AppConstants.statusApprovedText;
      case AppConstants.statusOnTheWay:
        return AppConstants.statusOnTheWayText;
      case AppConstants.statusCompleted:
        return AppConstants.statusCompletedText;
      case AppConstants.statusCanceled:
        return AppConstants.statusCanceledText;
      case AppConstants.statusRejected:
        return AppConstants.statusRejectedText;
      default:
        return 'غير معروف';
    }
  }

  static String getStatusBadgeType(int status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'warning';
      case AppConstants.statusApproved:
        return 'info';
      case AppConstants.statusOnTheWay:
        return 'info';
      case AppConstants.statusCompleted:
        return 'success';
      case AppConstants.statusCanceled:
        return 'danger';
      case AppConstants.statusRejected:
        return 'danger';
      default:
        return 'neutral';
    }
  }

  static bool isPending(int status) => status == AppConstants.statusPending;
  static bool isApproved(int status) => status == AppConstants.statusApproved;
  static bool isOnTheWay(int status) => status == AppConstants.statusOnTheWay;
  static bool isCompleted(int status) => status == AppConstants.statusCompleted;
  static bool isCanceled(int status) => status == AppConstants.statusCanceled;
  static bool isRejected(int status) => status == AppConstants.statusRejected;
  static bool isOngoing(int status) =>
      status == AppConstants.statusApproved || status == AppConstants.statusOnTheWay;
}
