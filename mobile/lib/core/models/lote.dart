import 'package:json_annotation/json_annotation.dart';

part 'lote.g.dart';

@JsonSerializable()
class Lote {
  final int id;
  final int usuario;
  final int? dieta;
  final String nombre;

  @JsonKey(name: 'cantidad_cabezas')
  final int cantidadCabezas;

  @JsonKey(name: 'peso_promedio_actual_kg')
  final String pesoPromedioActualKg;

  @JsonKey(name: 'etapa_productiva')
  final String etapaProductiva;

  final String estado;

  @JsonKey(name: 'fecha_registro')
  final DateTime fechaRegistro;

  const Lote({
    required this.id,
    required this.usuario,
    this.dieta,
    required this.nombre,
    required this.cantidadCabezas,
    required this.pesoPromedioActualKg,
    required this.etapaProductiva,
    required this.estado,
    required this.fechaRegistro,
  });

  factory Lote.fromJson(Map<String, dynamic> json) => _$LoteFromJson(json);
  Map<String, dynamic> toJson() => _$LoteToJson(this);
}
