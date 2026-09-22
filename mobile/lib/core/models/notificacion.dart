import 'package:json_annotation/json_annotation.dart';

part 'notificacion.g.dart';

@JsonSerializable()
class Notificacion {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  @JsonKey(name: 'referencia_tipo')
  final String? referenciaTipo;
  @JsonKey(name: 'referencia_id')
  final int? referenciaId;
  final bool leida;
  @JsonKey(name: 'fecha_creacion')
  final DateTime fechaCreacion;

  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.referenciaTipo,
    this.referenciaId,
    required this.leida,
    required this.fechaCreacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) =>
      _$NotificacionFromJson(json);
  Map<String, dynamic> toJson() => _$NotificacionToJson(this);
}
