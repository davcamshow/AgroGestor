import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/dieta.dart';
import '../models/dieta_insumo.dart';
import '../repositories/offline_repository.dart';

final dietasRepositoryProvider = Provider<OfflineRepository<Dieta>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OfflineRepository<Dieta>(
    entityType: 'dieta',
    endpoint: 'dietas/',
    apiClient: apiClient,
    fromJson: Dieta.fromJson,
    toJson: (d) => d.toJson(),
    idOf: (d) => d.id,
    placeholderFields: () => {
      'usuario': 0,
      'fecha_creacion': DateTime.now().toIso8601String(),
      'ultima_modificacion': DateTime.now().toIso8601String(),
    },
  );
});

final dietasProvider = FutureProvider.autoDispose<List<Dieta>>((ref) async {
  final repo = ref.read(dietasRepositoryProvider);
  return repo.getAll();
});

// dieta-insumos es una tabla relacional (dieta + insumo + porcentaje/cantidad),
// se queda online-only: no forma parte del alcance de BP-157/BP-159.
final dietaInsumosProvider =
    FutureProvider.autoDispose<List<DietaInsumo>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('dieta-insumos/');
  return (response.data as List).map((j) => DietaInsumo.fromJson(j)).toList();
});

class DietasNotifier extends StateNotifier<AsyncValue<List<Dieta>>> {
  final OfflineRepository<Dieta> _repo;
  final ApiClient _client;

  DietasNotifier(this._repo, this._client) : super(const AsyncValue.loading()) {
    fetchDietas();
  }

  Future<void> fetchDietas() async {
    state = const AsyncValue.loading();
    try {
      final dietas = await _repo.getAll();
      state = AsyncValue.data(dietas);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<int> createDieta(Map<String, dynamic> data) async {
    try {
      final dieta = await _repo.create(data);
      await fetchDietas();
      return dieta.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDieta(int id, Map<String, dynamic> data) async {
    try {
      await _repo.update(id, data);
      await fetchDietas();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDieta(int id) async {
    try {
      await _repo.delete(id);
      await fetchDietas();
    } catch (e) {
      rethrow;
    }
  }

  // --- dieta-insumos y procesar-consumo: relacional/acción de servidor,
  // requieren conexión. Fuera del alcance de BP-157/BP-159. Sin cambios.

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

final dietasNotifierProvider =
    StateNotifierProvider.autoDispose<DietasNotifier, AsyncValue<List<Dieta>>>(
        (ref) {
  return DietasNotifier(
    ref.read(dietasRepositoryProvider),
    ref.read(apiClientProvider),
  );
});
