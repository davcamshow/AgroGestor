import 'package:json_annotation/json_annotation.dart';

part 'auditoria_animal.g.dart';

@JsonSerializable()
class AuditoriaAnimal {
  final int id;
  final int animal;
  final int? usuario;
  final String campo;
  @JsonKey(name: 'valor_anterior')
  final String? valorAnterior;
  @JsonKey(name: 'valor_nuevo')
  final String? valorNuevo;
  @JsonKey(name: 'fecha_cambio')
  final DateTime fechaCambio;
  @JsonKey(name: 'ip_address')
  final String? ipAddress;

  const AuditoriaAnimal({
    required this.id,
    required this.animal,
    this.usuario,
    required this.campo,
    this.valorAnterior,
    this.valorNuevo,
    required this.fechaCambio,
    this.ipAddress,
  });

  factory AuditoriaAnimal.fromJson(Map<String, dynamic> json) =>
      _$AuditoriaAnimalFromJson(json);
  Map<String, dynamic> toJson() => _$AuditoriaAnimalToJson(this);

  /// Etiqueta legible del campo
  static String labelDeCampo(String campo) {
    const etiquetas = {
      'numero_arete': 'Número de Caravana',
      'nombre': 'Nombre',
      'raza': 'Raza',
      'sexo': 'Sexo',
      'fecha_nacimiento': 'Fecha de Nacimiento',
      'color': 'Color',
      'peso_nacimiento_kg': 'Peso al Nacer (kg)',
      'estado': 'Estado',
      'lote': 'Lote',
      'madre': 'Madre',
      'padre': 'Padre',
    };
    return etiquetas[campo] ?? campo;
  }
}
