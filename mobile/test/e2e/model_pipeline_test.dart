import 'package:flutter_test/flutter_test.dart';
import 'package:bovion/core/models/lote.dart';
import 'package:bovion/core/models/dieta.dart';
import 'package:bovion/core/models/insumo.dart';
import 'package:bovion/core/models/proveedor.dart';

void main() {
  group('E2E: Pipeline completo de serialización de datos del rancho', () {
    test('Escenario 1: Crear y serializar datos completos de un lote', () {
      final lote = Lote(
        id: 1,
        usuario: 1,
        dieta: 3,
        nombre: 'Lote Engorda Norte',
        cantidadCabezas: 80,
        pesoPromedioActualKg: '320.75',
        etapaProductiva: 'engorda',
        estado: 'activo',
        fechaRegistro: DateTime(2024, 6, 1),
      );

      final json = lote.toJson();
      final restored = Lote.fromJson(json);

      expect(restored.nombre, 'Lote Engorda Norte');
      expect(restored.cantidadCabezas, 80);
      expect(restored.etapaProductiva, 'engorda');
      expect(restored.pesoPromedioActualKg, '320.75');
      expect(restored.dieta, 3);
    });

    test('Escenario 2: Pipeline de insumo con proveedor', () {
      final proveedor = Proveedor(
        id: 1,
        usuario: 1,
        nombre_empresa: 'AgroVet S.A.',
        contacto: 'Carlos López',
        telefono: '555-9876',
        email: 'carlos@agrovet.com',
        notas: 'Pago a 30 días',
      );

      final insumo = Insumo(
        id: 10,
        usuario: 1,
        categoria: 2,
        proveedor_preferido: 1,
        nombre: 'Sorgo',
        cantidadActualKg: '15000.0',
        stockMinimoKg: '3000.0',
        costoKg: '4.75',
        fechaActualizacion: DateTime(2024, 5, 15),
      );

      final provJson = proveedor.toJson();
      final provRestored = Proveedor.fromJson(provJson);
      expect(provRestored.nombre_empresa, 'AgroVet S.A.');
      expect(provRestored.contacto, 'Carlos López');

      final insJson = insumo.toJson();
      final insRestored = Insumo.fromJson(insJson);
      expect(insRestored.nombre, 'Sorgo');
      expect(insRestored.proveedor_preferido, 1);
      expect(insRestored.cantidadActualKg, '15000.0');
    });

    test('Escenario 3: Dieta con todos los campos opcionales', () {
      final dieta = Dieta(
        id: 5,
        usuario: 1,
        nombre: 'Ración Final',
        objetivo: 'Finalización',
        estado: 'activo',
        costoEstimadoKg: '15.30',
        fechaCreacion: DateTime(2024, 2, 1),
        ultimaModificacion: DateTime(2024, 4, 10),
        tipoFormulacion: 'kg',
        cantidadKgCabeza: '8.0',
        periodicidad: 'diario',
      );

      final json = dieta.toJson();
      final restored = Dieta.fromJson(json);

      expect(restored.nombre, 'Ración Final');
      expect(restored.tipoFormulacion, 'kg');
      expect(restored.cantidadKgCabeza, '8.0');
      expect(restored.periodicidad, 'diario');
      expect(restored.costoEstimadoKg, '15.30');
    });
  });
}
