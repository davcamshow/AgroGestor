import 'package:json_annotation/json_annotation.dart';

part 'categoria_insumo.g.dart';

@JsonSerializable()
class CategoriaInsumo {
  final int id;
  final int usuario;
  final String nombre;

  const CategoriaInsumo({
    required this.id,
    required this.usuario,
    required this.nombre,
  });

  factory CategoriaInsumo.fromJson(Map<String, dynamic> json) =>
      _$CategoriaInsumoFromJson(json);
  Map<String, dynamic> toJson() => _$CategoriaInsumoToJson(this);
}
