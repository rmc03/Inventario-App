import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/features/inventario/presentation/producto_form_screen.dart';

void main() {
  testWidgets(
    'closes create category dialog from product form without errors',
    (tester) async {
      await _openCreateCategoryDialog(tester);

      expect(find.text('Nueva categoría'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nueva categoría'), findsNothing);
      expect(find.text('Crear nueva categoría'), findsNothing);
    },
  );

  testWidgets('saves category from product form without errors', (
    tester,
  ) async {
    await _openCreateCategoryDialog(tester);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Aceites',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nueva categoría'), findsNothing);
    expect(find.text('Aceites'), findsOneWidget);
  });
}

Future<void> _openCreateCategoryDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: ProductoFormScreen())),
  );

  await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Crear nueva categoría').last);
  await tester.pumpAndSettle();
}
