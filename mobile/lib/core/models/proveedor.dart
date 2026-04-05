import 'package:json_annotation/json_annotation.dart';

part 'proveedor.g.dart';

@JsonSerializable()
class Proveedor {
  final int id;
  final int usuario;
  final String nombre_empresa;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? notas;

  const Proveedor({
    required this.id,
    required this.usuario,
    required this.nombre_empresa,
    this.contacto,
    this.telefono,
    this.email,
    this.notas,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) => _$ProveedorFromJson(json);
  Map<String, dynamic> toJson() => _$ProveedorToJson(this);
}
