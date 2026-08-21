double? _doubleValue(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
int? _intValue(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');

class UbicacionClima {
  final bool configurada;
  final double? latitud;
  final double? longitud;
  final String? direccion;

  const UbicacionClima(
      {required this.configurada, this.latitud, this.longitud, this.direccion});

  factory UbicacionClima.fromJson(Map<String, dynamic> json) => UbicacionClima(
        configurada: json['configurada'] == true ||
            (json['latitud'] != null && json['longitud'] != null),
        latitud: _doubleValue(json['latitud']),
        longitud: _doubleValue(json['longitud']),
        direccion: json['direccion']?.toString(),
      );
}

class CondicionesClima {
  final double? temperatura;
  final double? sensacionTermica;
  final int? humedad;
  final double? precipitacion;
  final double? lluvia;
  final double? viento;
  final double? rafagas;
  final int? codigoClima;
  final String descripcion;
  final bool? esDia;

  const CondicionesClima(
      {this.temperatura,
      this.sensacionTermica,
      this.humedad,
      this.precipitacion,
      this.lluvia,
      this.viento,
      this.rafagas,
      this.codigoClima,
      required this.descripcion,
      this.esDia});

  factory CondicionesClima.fromJson(Map<String, dynamic> json) =>
      CondicionesClima(
        temperatura: _doubleValue(json['temperatura']),
        sensacionTermica: _doubleValue(json['sensacion_termica']),
        humedad: _intValue(json['humedad']),
        precipitacion: _doubleValue(json['precipitacion']),
        lluvia: _doubleValue(json['lluvia']),
        viento: _doubleValue(json['viento']),
        rafagas: _doubleValue(json['rafagas']),
        codigoClima: _intValue(json['codigo_clima']),
        descripcion: json['descripcion']?.toString() ?? 'Condición desconocida',
        esDia: json['es_dia'] is bool ? json['es_dia'] as bool : null,
      );
}

class PronosticoClima {
  final int? probabilidadLluviaMaxima;
  final double? precipitacionAcumulada;
  const PronosticoClima(
      {this.probabilidadLluviaMaxima, this.precipitacionAcumulada});
  factory PronosticoClima.fromJson(Map<String, dynamic> json) =>
      PronosticoClima(
        probabilidadLluviaMaxima: _intValue(json['probabilidad_lluvia_maxima']),
        precipitacionAcumulada: _doubleValue(json['precipitacion_acumulada']),
      );
}

class RiesgoClima {
  final String nivel;
  final String tipo;
  final String titulo;
  final String mensaje;
  final List<String> recomendaciones;
  final double? thi;
  final String? advertencia;
  const RiesgoClima(
      {required this.nivel,
      required this.tipo,
      required this.titulo,
      required this.mensaje,
      required this.recomendaciones,
      this.thi,
      this.advertencia});
  factory RiesgoClima.fromJson(Map<String, dynamic> json) => RiesgoClima(
        nivel: json['nivel']?.toString() ?? 'normal',
        tipo: json['tipo']?.toString() ?? 'condiciones_normales',
        titulo: json['titulo']?.toString() ?? 'Condiciones del clima',
        mensaje: json['mensaje']?.toString() ?? '',
        recomendaciones: (json['recomendaciones'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(),
        thi: _doubleValue(json['thi']),
        advertencia: json['advertencia']?.toString(),
      );
}

class ClimaRancho {
  final UbicacionClima ubicacion;
  final CondicionesClima actual;
  final PronosticoClima pronostico;
  final RiesgoClima riesgo;
  final DateTime? actualizadoEn;
  const ClimaRancho(
      {required this.ubicacion,
      required this.actual,
      required this.pronostico,
      required this.riesgo,
      this.actualizadoEn});
  factory ClimaRancho.fromJson(Map<String, dynamic> json) => ClimaRancho(
        ubicacion: UbicacionClima.fromJson(
            Map<String, dynamic>.from(json['ubicacion'] as Map? ?? const {})),
        actual: CondicionesClima.fromJson(
            Map<String, dynamic>.from(json['actual'] as Map? ?? const {})),
        pronostico: PronosticoClima.fromJson(Map<String, dynamic>.from(
            json['pronostico_24h'] as Map? ?? const {})),
        riesgo: RiesgoClima.fromJson(
            Map<String, dynamic>.from(json['riesgo'] as Map? ?? const {})),
        actualizadoEn:
            DateTime.tryParse(json['actualizado_en']?.toString() ?? ''),
      );
}
