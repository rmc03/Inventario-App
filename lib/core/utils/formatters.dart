import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

final compactDateFormatter = DateFormat('dd/MM/yyyy');
final timeFormatter = DateFormat('HH:mm');

String formatCurrency(num value) => currencyFormatter.format(value);

String pluralize(String singular, String plural, int count) => count == 1 ? singular : plural;

String ventasLabel(int count) => '$count ${pluralize('venta', 'ventas', count)}';
String articulosLabel(int count) => '$count ${pluralize('artículo', 'artículos', count)}';
