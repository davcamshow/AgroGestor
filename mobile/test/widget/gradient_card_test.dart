import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bovion/widgets/gradient_card.dart';

void main() {
  testWidgets('renderiza el widget hijo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientCard(
            child: Text('Contenido del card'),
          ),
        ),
      ),
    );
    expect(find.text('Contenido del card'), findsOneWidget);
  });

  testWidgets('es tappable cuando onTap es proporcionado', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientCard(
            child: const Text('Tappable'),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tappable'));
    expect(tapped, isTrue);
  });

  testWidgets('no renderiza InkWell cuando no hay onTap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientCard(
            child: Text('No tap'),
          ),
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
  });
}
