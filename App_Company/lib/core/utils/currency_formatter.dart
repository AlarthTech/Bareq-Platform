import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'ar');
  
  static String format(double amount, {String currency = AppConstants.currency}) {
    return '${_numberFormat.format(amount)} $currency';
  }
  
  static String formatRevenue(double amount) {
    return format(amount, currency: AppConstants.currencyRevenue);
  }
  
  static String formatWithoutCurrency(double amount) {
    return _numberFormat.format(amount);
  }
}
