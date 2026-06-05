import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/app.dart';

void main() {
  testWidgets('shows login screen on cold start', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: InventarioApp()));
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsWidgets);
    expect(find.text('Gestión de\nInventario'), findsOneWidget);
  });
}
