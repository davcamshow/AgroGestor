import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovion/core/models/animal.dart';
import 'package:bovion/widgets/animal_avatar.dart';

Animal _animal({String? foto}) => Animal(
      id: 1,
      usuario: 1,
      numeroArete: 'A-123',
      sexo: 'H',
      estado: 'activo',
      fechaRegistro: DateTime(2026, 1, 1),
      fotoUrl: foto,
    );

void main() {
  testWidgets('muestra la inicial del arete si no hay foto', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AnimalAvatar(animal: _animal())),
      ),
    );

    expect(find.text('A'), findsOneWidget);
  });
}
