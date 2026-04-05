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

  Future<void> createDieta(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('dietas/', data: data);
      await fetchDietas();
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

  Future<void> addInsumoToDieta(int dietaId, int insumoId, double porcentaje) async {
    try {
      await _client.dio.post('dieta-insumos/', data: {
        'dieta': dietaId,
        'insumo': insumoId,
        'porcentaje_inclusion': porcentaje.toString(),
      });
      await fetchDietas();
    } catch (e) {
      rethrow;
    }
  }
}

final dietasNotifierProvider = StateNotifierProvider.autoDispose<DietasNotifier, AsyncValue<List<Dieta>>>((ref) {
  return DietasNotifier(ref.read(apiClientProvider));
});
