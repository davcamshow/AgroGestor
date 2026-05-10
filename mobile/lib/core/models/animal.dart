class Animal {
  final int id;
  final int usuario;
  final int? loteId;
  final int? madreId;
  final int? padreId;
  final String numeroArete;
  final String? nombre;
  final String? raza;
  final String sexo;
  final DateTime? fechaNacimiento;
  final String? color;
  final String? pesoNacimientoKg;
  final String estado;
  final DateTime fechaRegistro;
  final int? edadDias;
  final String? ultimoPesoKg;
  final double? ultimoPeso;
  final DateTime? fechaUltimoPeso;
  final DateTime? fechaUltimoParto;
  final int? partosCount;
  final int? diasLactancia;
  final int totalEventosSanitarios;
  final Map<String, dynamic>? ultimoEvento;

  Animal({
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
    this.ultimoPeso,
    this.fechaUltimoPeso,
    this.fechaUltimoParto,
    this.partosCount,
    this.diasLactancia,
    this.totalEventosSanitarios = 0,
    this.ultimoEvento,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) {
        if (val.isEmpty) return null;
        try { return DateTime.parse(val); } catch (_) { return null; }
      }
      return null;
    }

    double parseDouble(dynamic val) {
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0;
      return 0;
    }

    return Animal(
      id: parseInt(json['id']),
      usuario: parseInt(json['usuario']),
      loteId: json['lote'] != null ? parseInt(json['lote']) : null,
      madreId: json['madre'] != null ? parseInt(json['madre']) : null,
      padreId: json['padre'] != null ? parseInt(json['padre']) : null,
      numeroArete: json['numero_arete']?.toString() ?? '',
      nombre: json['nombre']?.toString(),
      raza: json['raza']?.toString(),
      sexo: json['sexo']?.toString() ?? 'M',
      fechaNacimiento: parseDate(json['fecha_nacimiento']),
      color: json['color']?.toString(),
      pesoNacimientoKg: json['peso_nacimiento_kg']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      fechaRegistro: parseDate(json['fecha_registro']) ?? DateTime.now(),
      edadDias: json['edad_dias'] != null ? parseInt(json['edad_dias']) : null,
      ultimoPesoKg: json['ultimo_peso_kg']?.toString(),
      ultimoPeso: json['ultimo_peso'] != null ? parseDouble(json['ultimo_peso']) : null,
      fechaUltimoPeso: parseDate(json['fecha_ultimo_peso']),
      fechaUltimoParto: parseDate(json['fecha_ultimo_parto']),
      partosCount: json['partos_count'] != null ? parseInt(json['partos_count']) : null,
      diasLactancia: json['dias_lactancia'] != null ? parseInt(json['dias_lactancia']) : null,
      totalEventosSanitarios: json['total_eventos_sanitarios'] != null ? parseInt(json['total_eventos_sanitarios']) : 0,
      ultimoEvento: json['ultimo_evento'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario': usuario,
        'lote': loteId,
        'madre': madreId,
        'padre': padreId,
        'numero_arete': numeroArete,
        'nombre': nombre,
        'raza': raza,
        'sexo': sexo,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T')[0],
        'color': color,
        'peso_nacimiento_kg': pesoNacimientoKg,
        'estado': estado,
        'fecha_registro': fechaRegistro.toIso8601String(),
        'edad_dias': edadDias,
        'ultimo_peso_kg': ultimoPesoKg,
        'ultimo_peso': ultimoPeso,
        'fecha_ultimo_peso': fechaUltimoPeso?.toIso8601String().split('T')[0],
        'fecha_ultimo_parto': fechaUltimoParto?.toIso8601String().split('T')[0],
        'partos_count': partosCount,
        'dias_lactancia': diasLactancia,
        'total_eventos_sanitarios': totalEventosSanitarios,
        'ultimo_evento': ultimoEvento,
      };
}
