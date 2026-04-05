import 'package:json_annotation/json_annotation.dart';

part 'ciclo_reproductivo.g.dart';

@JsonSerializable()
class CicloReproductivo {
  final int id;
  final int animal;
  @JsonKey(name: 'tipo_servicio')
  final String tipoServicio;
  @JsonKey(name: 'fecha_servicio')
  final DateTime fechaServicio;
  @JsonKey(name: 'dias_gestacion')
  final int diasGestacion;
  @JsonKey(name: 'fecha_estimada_parto')
  final DateTime? fechaEstimadaParto;
  @JsonKey(name: 'fecha_parto_real')
  final DateTime? fechaPartoReal;
  final String estado;
  final String? notas;
  @JsonKey(name: 'dias_restantes_parto')
  final int? diasRestantesParto;

  const CicloReproductivo({
    required this.id,
    required this.animal,
    required this.tipoServicio,
    required this.fechaServicio,
    required this.diasGestacion,
    this.fechaEstimadaParto,
    this.fechaPartoReal,
    required this.estado,
    this.notas,
    this.diasRestantesParto,
  });

  factory CicloReproductivo.fromJson(Map<String, dynamic> json) =>
      _$CicloReproductivoFromJson(json);
  Map<String, dynamic> toJson() => _$CicloReproductivoToJson(this);
}
