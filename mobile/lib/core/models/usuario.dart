import 'package:json_annotation/json_annotation.dart';

part 'usuario.g.dart';

@JsonSerializable()
class Usuario {
  final int id;
  final String nombre_completo;
  final String email;
  final String? telefono;
  final String? rol_profesional;
  final String? cedula;
  final String? nombre_rancho;
  final String? direccion_rancho;
  final String moneda;
  final String unidad_peso;

  const Usuario({
    required this.id,
    required this.nombre_completo,
    required this.email,
    this.telefono,
    this.rol_profesional,
    this.cedula,
    this.nombre_rancho,
    this.direccion_rancho,
    this.moneda = 'MXN',
    this.unidad_peso = 'kg',
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => _$UsuarioFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioToJson(this);
}
