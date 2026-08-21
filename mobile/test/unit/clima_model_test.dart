import 'package:bovion/core/models/clima.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea enteros, decimales y campos opcionales', () {
    final clima = ClimaRancho.fromJson({
      'ubicacion': {
        'latitud': 25,
        'longitud': -100.5,
        'direccion': 'Monterrey'
      },
      'actual': {
        'temperatura': 31,
        'sensacion_termica': 34.2,
        'humedad': 78.0,
        'codigo_clima': 2
      },
      'pronostico_24h': {'probabilidad_lluvia_maxima': 70.0},
      'riesgo': {
        'nivel': 'precaucion',
        'recomendaciones': ['Agua']
      },
      'actualizado_en': '2026-08-19T16:30:00-06:00',
    });

    expect(clima.ubicacion.configurada, isTrue);
    expect(clima.actual.temperatura, 31.0);
    expect(clima.actual.humedad, 78);
    expect(clima.actual.descripcion, 'Condición desconocida');
    expect(clima.pronostico.precipitacionAcumulada, isNull);
    expect(clima.riesgo.recomendaciones, ['Agua']);
  });
}
