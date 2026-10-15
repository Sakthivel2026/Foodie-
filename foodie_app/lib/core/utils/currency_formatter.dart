import 'package:intl/intl.dart';

abstract class CurrencyFormatter {
  /// Formats integer paise into Indian Rupee (₹) format.
  /// Example: 25000 paise -> ₹250.00 or ₹250 depending on decimal preference.
  static String formatPaise(int paise, {bool showDecimals = true}) {
    final rupees = paise / 100.0;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(rupees);
  }
}
