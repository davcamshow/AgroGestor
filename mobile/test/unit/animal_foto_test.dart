import 'package:flutter_test/flutter_test.dart';
import 'package:bovion/core/models/animal.dart';

void main() {
  group('Animal foto', () {
    test('fromJson guarda la URL de la foto', () {
      final animal = Animal.fromJson({
        'id': 1,
        'usuario': 2,
        'numero_arete': 'MX-10',
        'nombre': 'Luna',
        'sexo': 'H',
        'estado': 'activo',
        'fecha_registro': '2026-01-15T10:00:00.000Z',
        'foto': 'http://localhost:8000/media/animales/2/luna.png',
      });

      expect(animal.fotoUrl, 'http://localhost:8000/media/animales/2/luna.png');
      expect(animal.tieneFoto, isTrue);
    });

    test('fromJson trata foto vacía o null como ausente', () {
      final sinFoto = Animal.fromJson({
        'id': 1,
        'usuario': 2,
        'numero_arete': 'MX-10',
        'sexo': 'H',
        'estado': 'activo',
        'fecha_registro': '2026-01-15T10:00:00.000Z',
        'foto': null,
      });
      final vacia = Animal.fromJson({
        ...sinFoto.toJson(),
        'foto': '',
      });

      expect(sinFoto.tieneFoto, isFalse);
      expect(vacia.tieneFoto, isFalse);
    });
  });
}
