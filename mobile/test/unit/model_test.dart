import 'package:flutter_test/flutter_test.dart';
import 'package:bovion/core/models/lote.dart';
import 'package:bovion/core/models/dieta.dart';
import 'package:bovion/core/models/insumo.dart';
import 'package:bovion/core/models/proveedor.dart';

void main() {
  group('Lote', () {
    test('fromJson crea instancia correcta', () {
      final json = {
        'id': 1,
        'usuario': 1,
        'nombre': 'Lote A',
        'cantidad_cabezas': 50,
        'peso_promedio_actual_kg': '250.5',
        'etapa_productiva': 'destete',
        'estado': 'activo',
        'fecha_registro': '2024-01-15T10:00:00.000Z',
      };
      final lote = Lote.fromJson(json);
      expect(lote.id, 1);
      expect(lote.nombre, 'Lote A');
      expect(lote.cantidadCabezas, 50);
      expect(lote.pesoPromedioActualKg, '250.5');
      expect(lote.etapaProductiva, 'destete');
      expect(lote.estado, 'activo');
    });

    test('toJson produce mapa correcto', () {
      final lote = Lote(
        id: 1,
        usuario: 1,
        nombre: 'Lote A',
        cantidadCabezas: 50,
        pesoPromedioActualKg: '250.5',
        etapaProductiva: 'destete',
        estado: 'activo',
        fechaRegistro: DateTime(2024, 1, 15),
      );
      final json = lote.toJson();
      expect(json['nombre'], 'Lote A');
      expect(json['cantidad_cabezas'], 50);
      expect(json['etapa_productiva'], 'destete');
    });

    test('round-trip preserva todos los campos', () {
      final original = Lote(
        id: 1,
        usuario: 1,
        dieta: 2,
        nombre: 'Lote B',
        cantidadCabezas: 100,
        pesoPromedioActualKg: '300.0',
        etapaProductiva: 'engorda',
        estado: 'activo',
        fechaRegistro: DateTime(2024, 3, 20),
      );
      final json = original.toJson();
      final restored = Lote.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.nombre, original.nombre);
      expect(restored.cantidadCabezas, original.cantidadCabezas);
      expect(restored.dieta, original.dieta);
      expect(restored.etapaProductiva, original.etapaProductiva);
    });
  });

  group('Dieta', () {
    test('fromJson crea instancia correcta', () {
      final json = {
        'id': 1,
        'usuario': 1,
        'nombre': 'Ración Engorda',
        'objetivo': 'Engorda',
        'estado': 'activo',
        'costo_estimado_kg': '12.50',
        'fecha_creacion': '2024-01-10T08:00:00.000Z',
        'ultima_modificacion': '2024-02-10T08:00:00.000Z',
      };
      final dieta = Dieta.fromJson(json);
      expect(dieta.id, 1);
      expect(dieta.nombre, 'Ración Engorda');
      expect(dieta.costoEstimadoKg, '12.50');
    });

    test('fromJson maneja campos opcionales', () {
      final json = {
        'id': 2,
        'usuario': 1,
        'nombre': 'Suplemento',
        'objetivo': 'Complemento',
        'estado': 'activo',
        'costo_estimado_kg': '8.00',
        'fecha_creacion': '2024-01-10T08:00:00.000Z',
        'ultima_modificacion': '2024-02-10T08:00:00.000Z',
        'tipo_formulacion': 'porcentaje',
        'cantidad_kg_cabeza': '3.5',
        'periodicidad': 'diario',
      };
      final dieta = Dieta.fromJson(json);
      expect(dieta.tipoFormulacion, 'porcentaje');
      expect(dieta.cantidadKgCabeza, '3.5');
      expect(dieta.periodicidad, 'diario');
    });
  });

  group('Insumo', () {
    test('fromJson crea instancia correcta', () {
      final json = {
        'id': 1,
        'usuario': 1,
        'categoria': 2,
        'proveedor_preferido': 1,
        'nombre': 'Maíz',
        'cantidad_actual_kg': '5000.0',
        'stock_minimo_kg': '1000.0',
        'costo_kg': '5.50',
        'fecha_actualizacion': '2024-01-15T10:00:00.000Z',
      };
      final insumo = Insumo.fromJson(json);
      expect(insumo.nombre, 'Maíz');
      expect(insumo.cantidadActualKg, '5000.0');
      expect(insumo.costoKg, '5.50');
    });
  });

  group('Proveedor', () {
    test('fromJson crea instancia con todos los campos', () {
      final json = {
        'id': 1,
        'usuario': 1,
        'nombre_empresa': 'AgroInsumos S.A.',
        'contacto': 'Juan Pérez',
        'telefono': '555-1234',
        'email': 'juan@agroinsumos.com',
        'notas': 'Entrega cada lunes',
      };
      final proveedor = Proveedor.fromJson(json);
      expect(proveedor.nombre_empresa, 'AgroInsumos S.A.');
      expect(proveedor.contacto, 'Juan Pérez');
      expect(proveedor.telefono, '555-1234');
    });

    test('fromJson maneja nulos en opcionales', () {
      final json = {
        'id': 2,
        'usuario': 1,
        'nombre_empresa': 'Ganadero Express',
      };
      final proveedor = Proveedor.fromJson(json);
      expect(proveedor.contacto, isNull);
      expect(proveedor.email, isNull);
      expect(proveedor.notas, isNull);
    });
  });
}
