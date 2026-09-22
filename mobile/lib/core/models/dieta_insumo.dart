import 'package:json_annotation/json_annotation.dart';

part 'dieta_insumo.g.dart';

@JsonSerializable()
class DietaInsumo {
  final int id;
  final int dieta;
  final int insumo;

  @JsonKey(name: 'porcentaje_inclusion')
  final String? porcentajeInclusion;

  @JsonKey(name: 'cantidad_kg')
  final String? cantidadKg;

  const DietaInsumo({
    required this.id,
    required this.dieta,
    required this.insumo,
    this.porcentajeInclusion,
    this.cantidadKg,
  });

  factory DietaInsumo.fromJson(Map<String, dynamic> json) => _$DietaInsumoFromJson(json);
  Map<String, dynamic> toJson() => _$DietaInsumoToJson(this);
}
