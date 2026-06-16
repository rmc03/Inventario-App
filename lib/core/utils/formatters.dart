import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

final compactDateFormatter = DateFormat('dd/MM/yyyy');
final timeFormatter = DateFormat('HH:mm');

String formatCurrency(num value) => currencyFormatter.format(value);
