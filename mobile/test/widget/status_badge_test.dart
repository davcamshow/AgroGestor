import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bovion/widgets/status_badge.dart';

void main() {
  testWidgets('renderiza con label activo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'activo'),
        ),
      ),
    );
    expect(find.text('activo'), findsOneWidget);
  });

  testWidgets('renderiza con label vendido', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'vendido'),
        ),
      ),
    );
    expect(find.text('vendido'), findsOneWidget);
  });

  testWidgets('renderiza con label crítico', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'crítico'),
        ),
      ),
    );
    expect(find.text('crítico'), findsOneWidget);
  });

  testWidgets('renderiza con status desconocido usando gris por defecto', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'desconocido'),
        ),
      ),
    );
    expect(find.text('desconocido'), findsOneWidget);
  });

  testWidgets('tiene borderRadius circular (20)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'activo'),
        ),
      ),
    );
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, const BorderRadius.all(Radius.circular(20)));
  });
}
