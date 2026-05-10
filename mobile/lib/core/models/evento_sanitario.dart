class EventoSanitario {
  final int id;
  final int animalId;
  final String tipo;
  final String producto;
  final String? dosis;
  final DateTime fechaAplicacion;
  final DateTime? proximaAplicacion;
  final String? veterinario;
  final double costo;
  final String? notas;

  EventoSanitario({
    required this.id,
    required this.animalId,
    required this.tipo,
    required this.producto,
    this.dosis,
    required this.fechaAplicacion,
    this.proximaAplicacion,
    this.veterinario,
    required this.costo,
    this.notas,
  });

  factory EventoSanitario.fromJson(Map<String, dynamic> json) {
    return EventoSanitario(
      id: json['id'] ?? 0,
      animalId: json['animal'] ?? 0,
      tipo: json['tipo'] ?? '',
      producto: json['producto'] ?? '',
      dosis: json['dosis'],
      fechaAplicacion: json['fecha_aplicacion'] != null
          ? DateTime.parse(json['fecha_aplicacion'])
          : DateTime.now(),
      proximaAplicacion: json['proxima_aplicacion'] != null
          ? DateTime.parse(json['proxima_aplicacion'])
          : null,
      veterinario: json['veterinario'],
      costo: json['costo'] != null
          ? (json['costo'] is double
              ? json['costo']
              : double.tryParse(json['costo']?.toString() ?? '0') ?? 0)
          : 0,
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'animal': animalId,
        'tipo': tipo,
        'producto': producto,
        'dosis': dosis,
        'fecha_aplicacion': fechaAplicacion.toIso8601String().split('T')[0],
        'proxima_aplicacion': proximaAplicacion?.toIso8601String().split('T')[0],
        'veterinario': veterinario,
        'costo': costo,
        'notas': notas,
      };
}
