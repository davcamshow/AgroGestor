import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/dieta.dart';
import '../models/dieta_insumo.dart';

final dietasProvider = FutureProvider.autoDispose<List<Dieta>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('dietas/');
  return (response.data as List).map((j) => Dieta.fromJson(j)).toList();
});

final dietaInsumosProvider = FutureProvider.autoDispose<List<DietaInsumo>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('dieta-insumos/');
  return (response.data as List).map((j) => DietaInsumo.fromJson(j)).toList();
});

class DietasNotifier extends StateNotifier<AsyncValue<List<Dieta>>> {
  final ApiClient _client;

  DietasNotifier(this._client) : super(const AsyncValue.loading()) {
    fetchDietas();
  }

  Future<void> fetchDietas() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.dio.get('dietas/');
      final dietas = (response.data as List).map((j) => Dieta.fromJson(j)).toList();
      state = AsyncValue.data(dietas);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<int> createDieta(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('dietas/', data: data);
      final id = (response.data as Map)['id'] as int;
      await fetchDietas();
      return id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDieta(int id, Map<String, dynamic> data) async {
    try {
      await _client.dio.patch('dietas/$id/', data: data);
      await fetchDietas();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDieta(int id) async {
    try {
      await _client.dio.delete('dietas/$id/');
      await fetchDietas();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addInsumoToDieta(int dietaId, int insumoId,
      {double? porcentaje, double? cantidadKg}) async {
    try {
      await _client.dio.post('dieta-insumos/', data: {
        'dieta': dietaId,
        'insumo': insumoId,
        if (porcentaje != null) 'porcentaje_inclusion': porcentaje.toString(),
        if (cantidadKg != null) 'cantidad_kg': cantidadKg.toString(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDietaInsumo(int id, Map<String, dynamic> data) async {
    try {
      await _client.dio.patch('dieta-insumos/$id/', data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDietaInsumo(int id) async {
    try {
      await _client.dio.delete('dieta-insumos/$id/');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> procesarConsumo() async {
    try {
      final response = await _client.dio.post('dietas/procesar-consumo/');
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      rethrow;
    }
  }
}

final dietasNotifierProvider = StateNotifierProvider.autoDispose<DietasNotifier, AsyncValue<List<Dieta>>>((ref) {
  return DietasNotifier(ref.read(apiClientProvider));
});