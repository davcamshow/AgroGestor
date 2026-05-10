class RegistroPeso {
  final int id;
  final int animalId;
  final DateTime fechaPesaje;
  final String pesoKg;
  final int? condicionCorporal;
  final String? gananciaDiariaKg;
  final String? notas;

  RegistroPeso({
    required this.id,
    required this.animalId,
    required this.fechaPesaje,
    required this.pesoKg,
    this.condicionCorporal,
    this.gananciaDiariaKg,
    this.notas,
  });

  factory RegistroPeso.fromJson(Map<String, dynamic> json) {
    return RegistroPeso(
      id: json['id'] ?? 0,
      animalId: json['animal'] ?? 0,
      fechaPesaje: json['fecha_pesaje'] != null
          ? DateTime.parse(json['fecha_pesaje'])
          : DateTime.now(),
      pesoKg: json['peso_kg']?.toString() ?? '0',
      condicionCorporal: json['condicion_corporal'],
      gananciaDiariaKg: json['ganancia_diaria_kg']?.toString(),
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'animal': animalId,
        'fecha_pesaje': fechaPesaje.toIso8601String().split('T')[0],
        'peso_kg': pesoKg,
        'condicion_corporal': condicionCorporal,
        'ganancia_diaria_kg': gananciaDiariaKg,
        'notas': notas,
      };
}
