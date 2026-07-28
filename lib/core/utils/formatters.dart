import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
final compactCurrencyFormatter = NumberFormat.compactCurrency(
  symbol: r'$',
  decimalDigits: 0,
);

final compactDateFormatter = DateFormat('dd/MM/yyyy');
final timeFormatter = DateFormat('hh:mm a');

/// Format currency with compact notation for large numbers (e.g., $1.2M, $500K)
String formatCurrency(num value) {
  if (value.abs() >= 1000000) {
    return compactCurrencyFormatter.format(value);
  }
  return currencyFormatter.format(value);
}

/// Format currency always with full notation (no compact)
String formatCurrencyFull(num value) => currencyFormatter.format(value);

String pluralize(String singular, String plural, int count) => count == 1 ? singular : plural;

String ventasLabel(int count) => '$count ${pluralize('venta', 'ventas', count)}';
String articulosLabel(int count) => '$count ${pluralize('artículo', 'artículos', count)}';
