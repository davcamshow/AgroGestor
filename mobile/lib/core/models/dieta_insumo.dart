import 'package:json_annotation/json_annotation.dart';

part 'dieta_insumo.g.dart';

@JsonSerializable()
class DietaInsumo {
  final int id;
  final int dieta;
  final int insumo;

  @JsonKey(name: 'porcentaje_inclusion')
  final String porcentajeInclusion;

  const DietaInsumo({
    required this.id,
    required this.dieta,
    required this.insumo,
    required this.porcentajeInclusion,
  });

  factory DietaInsumo.fromJson(Map<String, dynamic> json) => _$DietaInsumoFromJson(json);
  Map<String, dynamic> toJson() => _$DietaInsumoToJson(this);
}
