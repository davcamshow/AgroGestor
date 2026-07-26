import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bovion/widgets/status_badge.dart';
import 'package:bovion/widgets/gradient_card.dart';
import 'package:bovion/widgets/empty_state.dart';
import 'package:bovion/widgets/loading_shimmer.dart';

void main() {
  group('E2E: Composición de widgets en pantalla de dashboard', () {
    testWidgets('Escenario 1: Dashboard con KPI-style GradientCard y StatusBadge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  GradientCard(
                    child: Column(
                      children: [
                        Text('Total Animales'),
                        Text('150'),
                        StatusBadge(status: 'activo'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total Animales'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('activo'), findsOneWidget);
    });

    testWidgets('Escenario 2: EmptyState sin botón (solo info)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.pets,
              title: 'Sin animales',
              description: 'Agrega tu primer animal para comenzar',
            ),
          ),
        ),
      );

      expect(find.text('Sin animales'), findsOneWidget);
      expect(find.text('Agrega tu primer animal para comenzar'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('Escenario 3: LoadingShimmer y GradientCard para estado de carga', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                GradientCard(
                  child: SizedBox(
                    height: 100,
                    child: Center(child: Text('Resumen')),
                  ),
                ),
                SizedBox(height: 16),
                LoadingShimmerListItem(lines: 3),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Resumen'), findsOneWidget);
      expect(find.byType(Shimmer), findsWidgets);
    });
  });
}
