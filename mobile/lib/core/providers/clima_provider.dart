import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/clima.dart';

sealed class ClimaDashboardState {
  const ClimaDashboardState();
}

class ClimaSinUbicacion extends ClimaDashboardState {
  const ClimaSinUbicacion();
}

class ClimaDisponible extends ClimaDashboardState {
  final ClimaRancho clima;
  const ClimaDisponible(this.clima);
}

class ClimaError extends ClimaDashboardState {
  final String mensaje;
  const ClimaError(this.mensaje);
}

class ClimaRepository {
  final ApiClient _client;
  ClimaRepository(this._client);
  Future<UbicacionClima> getLocation() async =>
      UbicacionClima.fromJson(Map<String, dynamic>.from(
          await _client.get('clima/ubicacion/', forceRefresh: true)));
  Future<UbicacionClima> saveLocation(
          double latitude, double longitude) async =>
      UbicacionClima.fromJson(Map<String, dynamic>.from(
          await _client.put('clima/ubicacion/', data: {
        'latitud': double.parse(latitude.toStringAsFixed(6)),
        'longitud': double.parse(longitude.toStringAsFixed(6)),
      })));
  Future<ClimaRancho> getWeather() async =>
      ClimaRancho.fromJson(Map<String, dynamic>.from(
          await _client.get('clima/actual/', forceRefresh: true)));
}

final climaRepositoryProvider = Provider<ClimaRepository>(
    (ref) => ClimaRepository(ref.read(apiClientProvider)));
final climaProvider =
    StateNotifierProvider<ClimaController, AsyncValue<ClimaDashboardState>>(
        (ref) => ClimaController(ref.read(climaRepositoryProvider))..load());

class ClimaController extends StateNotifier<AsyncValue<ClimaDashboardState>> {
  final ClimaRepository _repository;
  ClimaController(this._repository) : super(const AsyncLoading());

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final location = await _repository.getLocation();
      if (!location.configurada) {
        state = const AsyncData(ClimaSinUbicacion());
        return;
      }
      state = AsyncData(ClimaDisponible(await _repository.getWeather()));
    } on DioException catch (error) {
      final data = error.response?.data;
      if (error.response?.statusCode == 409 &&
          data is Map &&
          data['code'] == 'LOCATION_REQUIRED') {
        state = const AsyncData(ClimaSinUbicacion());
      } else {
        state = AsyncData(ClimaError(_message(error)));
      }
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<UbicacionClima> saveLocation(double latitude, double longitude) async {
    final location = await _repository.saveLocation(latitude, longitude);
    await load();
    return location;
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'No fue posible consultar el clima. Revisa tu conexión e intenta nuevamente.';
  }
}
