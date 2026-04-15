import 'package:intl/intl.dart';

class AppFormat {
  static String currency(dynamic value) {
    if (value == null) return 'Rp. 0';
    
    double amount;
    if (value is String) {
      amount = double.tryParse(value) ?? 0;
    } else if (value is int) {
      amount = value.toDouble();
    } else if (value is double) {
      amount = value;
    } else {
      amount = 0;
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    
    return formatter.format(amount);
  }
}
