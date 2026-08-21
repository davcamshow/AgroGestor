import 'package:bovion/core/models/clima.dart';
import 'package:bovion/core/providers/clima_provider.dart';
import 'package:bovion/widgets/clima_ganado_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClimaRepository implements ClimaRepository {
  UbicacionClima location;
  ClimaRancho weather;
  bool fail;
  int weatherCalls = 0;
  FakeClimaRepository(
      {required this.location, required this.weather, this.fail = false});
  @override
  Future<UbicacionClima> getLocation() async => location;
  @override
  Future<ClimaRancho> getWeather() async {
    weatherCalls++;
    if (fail) throw Exception('sin red');
    return weather;
  }

  @override
  Future<UbicacionClima> saveLocation(double latitude, double longitude) async {
    location = UbicacionClima(
        configurada: true,
        latitud: latitude,
        longitud: longitude,
        direccion: 'Nueva ubicación');
    return location;
  }
}

ClimaRancho sampleWeather() => ClimaRancho(
      ubicacion: const UbicacionClima(
          configurada: true,
          latitud: 25.6,
          longitud: -100.3,
          direccion: 'Monterrey, Nuevo León'),
      actual: const CondicionesClima(
          temperatura: 31.2,
          sensacionTermica: 34.1,
          humedad: 78,
          viento: 14.2,
          codigoClima: 2,
          descripcion: 'Parcialmente nublado'),
      pronostico: const PronosticoClima(
          probabilidadLluviaMaxima: 70, precipitacionAcumulada: 12.4),
      riesgo: const RiesgoClima(
          nivel: 'precaucion',
          tipo: 'estres_calor',
          titulo: 'Precaución por estrés térmico',
          mensaje: 'Condiciones que pueden afectar al ganado.',
          recomendaciones: ['Mantén agua disponible.']),
      actualizadoEn: DateTime(2026, 8, 19, 16, 30),
    );

Widget appWith(FakeClimaRepository repository) => ProviderScope(
      overrides: [climaRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.all(8), child: ClimaGanadoCard())))),
    );

void main() {
  testWidgets('muestra solicitud de ubicación pendiente', (tester) async {
    await tester.pumpWidget(appWith(FakeClimaRepository(
        location: const UbicacionClima(configurada: false),
        weather: sampleWeather())));
    await tester.pumpAndSettle();
    expect(find.text('Establecer ubicación'), findsOneWidget);
    expect(find.textContaining('Configura la ubicación'), findsOneWidget);
  });

  testWidgets('muestra clima y no desborda en pantalla móvil', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(appWith(FakeClimaRepository(
        location: sampleWeather().ubicacion, weather: sampleWeather())));
    await tester.pumpAndSettle();
    expect(find.text('31.2°'), findsOneWidget);
    expect(find.text('Precaución por estrés térmico'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra error recuperable y reintenta', (tester) async {
    final repository = FakeClimaRepository(
        location: sampleWeather().ubicacion,
        weather: sampleWeather(),
        fail: true);
    await tester.pumpWidget(appWith(repository));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('31.2°'), findsOneWidget);
    expect(repository.weatherCalls, 2);
  });

  test('guardar ubicación recarga el clima', () async {
    final repository = FakeClimaRepository(
        location: const UbicacionClima(configurada: false),
        weather: sampleWeather());
    final controller = ClimaController(repository);
    await controller.saveLocation(19.4, -99.1);
    expect(repository.weatherCalls, 1);
    expect(controller.state.value, isA<ClimaDisponible>());
  });
}
