import 'package:json_annotation/json_annotation.dart';

part 'dieta.g.dart';

@JsonSerializable()
class Dieta {
  final int id;
  final int usuario;
  final String nombre;
  final String objetivo;
  final String estado;

  @JsonKey(name: 'costo_estimado_kg')
  final String costoEstimadoKg;

  @JsonKey(name: 'fecha_creacion')
  final DateTime fechaCreacion;

  @JsonKey(name: 'ultima_modificacion')
  final DateTime ultimaModificacion;

  const Dieta({
    required this.id,
    required this.usuario,
    required this.nombre,
    required this.objetivo,
    required this.estado,
    required this.costoEstimadoKg,
    required this.fechaCreacion,
    required this.ultimaModificacion,
  });

  factory Dieta.fromJson(Map<String, dynamic> json) => _$DietaFromJson(json);
  Map<String, dynamic> toJson() => _$DietaToJson(this);
}
