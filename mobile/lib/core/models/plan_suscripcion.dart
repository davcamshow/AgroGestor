class PlanSuscripcion {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final double precioMxn;
  final double precioAnual;
  final int limiteAnimales;
  final int limiteUsuarios;
  final bool incluyeModuloAnimales;
  final bool incluyeModuloLotes;
  final bool incluyeModuloDietas;
  final bool incluyeModuloSanitaria;
  final bool incluyeReportesAvanzados;
  final bool incluyeApi;
  final bool soportePrioritario;
  final bool activo;

  PlanSuscripcion({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.precioMxn,
    required this.precioAnual,
    required this.limiteAnimales,
    required this.limiteUsuarios,
    required this.incluyeModuloAnimales,
    required this.incluyeModuloLotes,
    required this.incluyeModuloDietas,
    required this.incluyeModuloSanitaria,
    required this.incluyeReportesAvanzados,
    required this.incluyeApi,
    required this.soportePrioritario,
    required this.activo,
  });

  factory PlanSuscripcion.fromJson(Map<String, dynamic> json) {
    double parsePrecio(dynamic precio) {
      if (precio is double) return precio;
      if (precio is int) return precio.toDouble();
      if (precio is String) return double.tryParse(precio) ?? 0.0;
      return 0.0;
    }
    
    return PlanSuscripcion(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precioMxn: parsePrecio(json['precio_mxn']),
      precioAnual: parsePrecio(json['precio_anual']),
      limiteAnimales: json['limite_animales'] is int ? json['limite_animales'] : int.tryParse(json['limite_animales']?.toString() ?? '0') ?? 0,
      limiteUsuarios: json['limite_usuarios'] is int ? json['limite_usuarios'] : int.tryParse(json['limite_usuarios']?.toString() ?? '1') ?? 1,
      incluyeModuloAnimales: json['incluye_modulo_animales'] ?? true,
      incluyeModuloLotes: json['incluye_modulo_lotes'] ?? true,
      incluyeModuloDietas: json['incluye_modulo_dietas'] ?? true,
      incluyeModuloSanitaria: json['incluye_modulo_sanitaria'] ?? true,
      incluyeReportesAvanzados: json['incluye_reportes_avanzados'] ?? false,
      incluyeApi: json['incluye_api'] ?? false,
      soportePrioritario: json['soporte_prioritario'] ?? false,
      activo: json['activo'] ?? true,
    );
  }
}

class InfoPlanUsuario {
  final PlanSuscripcion plan;
  final int limiteAnimales;
  final int animalesActuales;
  final int animalesDisponibles;
  final int limiteUsuarios;
  final int usuariosActuales;
  final int usuariosDisponibles;
  final bool puedeCrearAnimal;
  final bool puedeInvitar;
  final bool incluyeReportesAvanzados;
  final bool incluyeApi;
  final bool soportePrioritario;
  final Map<String, dynamic>? suscripcion;

  InfoPlanUsuario({
    required this.plan,
    required this.limiteAnimales,
    required this.animalesActuales,
    required this.animalesDisponibles,
    required this.limiteUsuarios,
    required this.usuariosActuales,
    required this.usuariosDisponibles,
    required this.puedeCrearAnimal,
    required this.puedeInvitar,
    required this.incluyeReportesAvanzados,
    required this.incluyeApi,
    required this.soportePrioritario,
    this.suscripcion,
  });

  factory InfoPlanUsuario.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'];
    return InfoPlanUsuario(
      plan: planJson is String 
          ? PlanSuscripcion(id: 0, codigo: planJson, nombre: planJson, precioMxn: 0, precioAnual: 0, limiteAnimales: 50, limiteUsuarios: 1, incluyeModuloAnimales: true, incluyeModuloLotes: true, incluyeModuloDietas: true, incluyeModuloSanitaria: true, incluyeReportesAvanzados: false, incluyeApi: false, soportePrioritario: false, activo: true)
          : PlanSuscripcion.fromJson(planJson),
      limiteAnimales: json['limite_animales'] ?? 50,
      animalesActuales: json['animales_actuales'] ?? 0,
      animalesDisponibles: json['animales_disponibles'] ?? 50,
      limiteUsuarios: json['limite_usuarios'] ?? 1,
      usuariosActuales: json['usuarios_actuales'] ?? 0,
      usuariosDisponibles: json['usuarios_disponibles'] ?? 1,
      puedeCrearAnimal: json['puede_crear_animal'] ?? true,
      puedeInvitar: json['puede_invitar'] ?? false,
      incluyeReportesAvanzados: json['incluye_reportes_avanzados'] ?? false,
      incluyeApi: json['incluye_api'] ?? false,
      soportePrioritario: json['soporte_prioritario'] ?? false,
      suscripcion: json['suscripcion'],
    );
  }
}