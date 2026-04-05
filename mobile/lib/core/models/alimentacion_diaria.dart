import 'package:json_annotation/json_annotation.dart';

part 'alimentacion_diaria.g.dart';

@JsonSerializable()
class AlimentacionDiaria {
  final int id;
  final int lote;
  final int? dieta;
  final DateTime fecha;

  @JsonKey(name: 'cantidad_servida_kg')
  final String cantidadServidaKg;

  @JsonKey(name: 'costo_total_racion')
  final String costoTotalRacion;

  @JsonKey(name: 'usuario_registro')
  final int? usuarioRegistro;

  const AlimentacionDiaria({
    required this.id,
    required this.lote,
    this.dieta,
    required this.fecha,
    required this.cantidadServidaKg,
    required this.costoTotalRacion,
    this.usuarioRegistro,
  });

  factory AlimentacionDiaria.fromJson(Map<String, dynamic> json) =>
      _$AlimentacionDiariaFromJson(json);
  Map<String, dynamic> toJson() => _$AlimentacionDiariaToJson(this);
}
