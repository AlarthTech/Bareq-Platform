import '../constants/app_constants.dart';

class HealthCertificateHelper {
  static String getStatusText(DateTime? expiryDate) {
    if (expiryDate == null) return 'غير متوفر';
    
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < AppConstants.healthCertificateExpiredDays) {
      return 'منتهية';
    } else if (difference <= 0) {
      return 'منتهية';
    } else if (difference <= AppConstants.healthCertificateUrgentDays) {
      return 'عاجل';
    } else if (difference <= AppConstants.healthCertificateWarningDays) {
      return 'تنتهي قريباً';
    } else {
      return 'سارية';
    }
  }
  
  static String getStatusBadgeType(DateTime? expiryDate) {
    if (expiryDate == null) return 'neutral';
    
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < AppConstants.healthCertificateExpiredDays) {
      return 'danger';
    } else if (difference <= 0) {
      return 'danger';
    } else if (difference <= AppConstants.healthCertificateUrgentDays) {
      return 'warning';
    } else if (difference <= AppConstants.healthCertificateWarningDays) {
      return 'warning';
    } else {
      return 'success';
    }
  }
  
  static int getDaysUntilExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return 0;
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }
  
  static bool isExpiringSoon(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    final days = getDaysUntilExpiry(expiryDate);
    return days <= AppConstants.healthCertificateWarningDays && days > 0;
  }
  
  static bool isExpired(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    return expiryDate.isBefore(DateTime.now());
  }
  
  static bool needsAttention(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    final days = getDaysUntilExpiry(expiryDate);
    return days <= AppConstants.healthCertificateWarningDays;
  }
}
