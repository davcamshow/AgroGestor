import 'package:json_annotation/json_annotation.dart';

part 'evento_sanitario.g.dart';

@JsonSerializable()
class EventoSanitario {
  final int id;
  final int animal;
  final String tipo;
  final String producto;
  final String? dosis;
  @JsonKey(name: 'fecha_aplicacion')
  final DateTime fechaAplicacion;
  @JsonKey(name: 'proxima_aplicacion')
  final DateTime? proximaAplicacion;
  final String? veterinario;
  final String costo;
  final String? notas;

  const EventoSanitario({
    required this.id,
    required this.animal,
    required this.tipo,
    required this.producto,
    this.dosis,
    required this.fechaAplicacion,
    this.proximaAplicacion,
    this.veterinario,
    required this.costo,
    this.notas,
  });

  factory EventoSanitario.fromJson(Map<String, dynamic> json) =>
      _$EventoSanitarioFromJson(json);
  Map<String, dynamic> toJson() => _$EventoSanitarioToJson(this);
}
