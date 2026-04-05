import 'package:json_annotation/json_annotation.dart';

part 'movimiento_inventario.g.dart';

@JsonSerializable()
class MovimientoInventario {
  final int id;
  final int insumo;

  @JsonKey(name: 'tipo_movimiento')
  final String tipoMovimiento;

  @JsonKey(name: 'cantidad_kg')
  final String cantidadKg;

  @JsonKey(name: 'costo_unitario_kg')
  final String? costoUnitarioKg;

  @JsonKey(name: 'fecha_movimiento')
  final DateTime fechaMovimiento;

  final String? notas;

  const MovimientoInventario({
    required this.id,
    required this.insumo,
    required this.tipoMovimiento,
    required this.cantidadKg,
    this.costoUnitarioKg,
    required this.fechaMovimiento,
    this.notas,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) =>
      _$MovimientoInventarioFromJson(json);
  Map<String, dynamic> toJson() => _$MovimientoInventarioToJson(this);
}
