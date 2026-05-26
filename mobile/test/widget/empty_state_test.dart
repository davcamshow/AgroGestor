import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bovion/widgets/empty_state.dart';

void main() {
  testWidgets('renderiza icono, título y descripción', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.info_outline,
            title: 'Sin datos',
            description: 'No hay elementos para mostrar',
          ),
        ),
      ),
    );
    expect(find.text('Sin datos'), findsOneWidget);
    expect(find.text('No hay elementos para mostrar'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('muestra botón de acción cuando se proporciona', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.add_circle_outline,
            title: 'Vacío',
            description: 'Agrega un elemento',
            actionLabel: 'Agregar',
            onActionPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Agregar'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('no muestra botón cuando no se proporciona', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.info_outline,
            title: 'Sin datos',
            description: 'No hay elementos',
          ),
        ),
      ),
    );
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('ejecuta callback al presionar botón', (tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.add_circle_outline,
            title: 'Vacío',
            description: 'Agrega un elemento',
            actionLabel: 'Agregar',
            onActionPressed: () => pressed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Agregar'));
    expect(pressed, isTrue);
  });
}
