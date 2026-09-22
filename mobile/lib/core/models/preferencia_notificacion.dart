import 'package:json_annotation/json_annotation.dart';

part 'preferencia_notificacion.g.dart';

@JsonSerializable()
class PreferenciaNotificacion {
  final int id;
  @JsonKey(name: 'eventos_sanitarios')
  final bool eventosSanitarios;
  @JsonKey(name: 'partos_proximos')
  final bool partosProximos;
  @JsonKey(name: 'stock_bajo')
  final bool stockBajo;
  @JsonKey(name: 'dias_anticipacion_sanitario')
  final int diasAnticipacionSanitario;
  @JsonKey(name: 'dias_anticipacion_parto')
  final int diasAnticipacionParto;

  const PreferenciaNotificacion({
    required this.id,
    required this.eventosSanitarios,
    required this.partosProximos,
    required this.stockBajo,
    required this.diasAnticipacionSanitario,
    required this.diasAnticipacionParto,
  });

  factory PreferenciaNotificacion.fromJson(Map<String, dynamic> json) =>
      _$PreferenciaNotificacionFromJson(json);
  Map<String, dynamic> toJson() => _$PreferenciaNotificacionToJson(this);
}
