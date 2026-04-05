import 'package:json_annotation/json_annotation.dart';

part 'pesaje_lote.g.dart';

@JsonSerializable()
class PesajeLote {
  final int id;
  final int lote;

  @JsonKey(name: 'fecha_pesaje')
  final DateTime fechaPesaje;

  @JsonKey(name: 'peso_promedio_kg')
  final String pesoPromedioKg;

  @JsonKey(name: 'ganancia_diaria_promedio')
  final String? gananciaDiariaPromedio;

  final String? notas;

  const PesajeLote({
    required this.id,
    required this.lote,
    required this.fechaPesaje,
    required this.pesoPromedioKg,
    this.gananciaDiariaPromedio,
    this.notas,
  });

  factory PesajeLote.fromJson(Map<String, dynamic> json) => _$PesajeLoteFromJson(json);
  Map<String, dynamic> toJson() => _$PesajeLoteToJson(this);
}
