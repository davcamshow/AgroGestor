import 'package:json_annotation/json_annotation.dart';

part 'registro_peso.g.dart';

@JsonSerializable()
class RegistroPeso {
  final int id;
  final int animal;
  @JsonKey(name: 'fecha_pesaje')
  final DateTime fechaPesaje;
  @JsonKey(name: 'peso_kg')
  final String pesoKg;
  @JsonKey(name: 'condicion_corporal')
  final int? condicionCorporal;
  @JsonKey(name: 'ganancia_diaria_kg')
  final String? gananciaDiariaKg;
  final String? notas;

  const RegistroPeso({
    required this.id,
    required this.animal,
    required this.fechaPesaje,
    required this.pesoKg,
    this.condicionCorporal,
    this.gananciaDiariaKg,
    this.notas,
  });

  factory RegistroPeso.fromJson(Map<String, dynamic> json) =>
      _$RegistroPesoFromJson(json);
  Map<String, dynamic> toJson() => _$RegistroPesoToJson(this);
}
