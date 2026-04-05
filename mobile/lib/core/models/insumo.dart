import 'package:json_annotation/json_annotation.dart';

part 'insumo.g.dart';

@JsonSerializable()
class Insumo {
  final int id;
  final int usuario;
  final int? categoria;
  final int? proveedor_preferido;
  final String nombre;

  @JsonKey(name: 'cantidad_actual_kg')
  final String cantidadActualKg;

  @JsonKey(name: 'stock_minimo_kg')
  final String stockMinimoKg;

  @JsonKey(name: 'costo_kg')
  final String costoKg;

  @JsonKey(name: 'fecha_actualizacion')
  final DateTime fechaActualizacion;

  const Insumo({
    required this.id,
    required this.usuario,
    this.categoria,
    this.proveedor_preferido,
    required this.nombre,
    required this.cantidadActualKg,
    required this.stockMinimoKg,
    required this.costoKg,
    required this.fechaActualizacion,
  });

  factory Insumo.fromJson(Map<String, dynamic> json) => _$InsumoFromJson(json);
  Map<String, dynamic> toJson() => _$InsumoToJson(this);
}
