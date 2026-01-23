import 'package:intl/intl.dart';

class Formatters {
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatCurrency(double amount) {
    final format = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);
    return format.format(amount);
  }
}
