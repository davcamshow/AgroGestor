import 'package:json_annotation/json_annotation.dart';

part 'animal.g.dart';

@JsonSerializable()
class Animal {
  final int id;
  final int usuario;
  @JsonKey(name: 'lote')
  final int? loteId;
  @JsonKey(name: 'madre')
  final int? madreId;
  @JsonKey(name: 'padre')
  final int? padreId;
  @JsonKey(name: 'numero_arete')
  final String numeroArete;
  final String? nombre;
  final String? raza;
  final String sexo;
  @JsonKey(name: 'fecha_nacimiento')
  final DateTime? fechaNacimiento;
  final String? color;
  @JsonKey(name: 'peso_nacimiento_kg')
  final String? pesoNacimientoKg;
  final String estado;
  @JsonKey(name: 'fecha_registro')
  final DateTime fechaRegistro;
  @JsonKey(name: 'edad_dias')
  final int? edadDias;
  @JsonKey(name: 'ultimo_peso_kg')
  final String? ultimoPesoKg;

  const Animal({
    required this.id,
    required this.usuario,
    this.loteId,
    this.madreId,
    this.padreId,
    required this.numeroArete,
    this.nombre,
    this.raza,
    required this.sexo,
    this.fechaNacimiento,
    this.color,
    this.pesoNacimientoKg,
    required this.estado,
    required this.fechaRegistro,
    this.edadDias,
    this.ultimoPesoKg,
  });

  factory Animal.fromJson(Map<String, dynamic> json) => _$AnimalFromJson(json);
  Map<String, dynamic> toJson() => _$AnimalToJson(this);
}
