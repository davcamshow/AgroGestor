import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/insumo.dart';
import '../models/movimiento_inventario.dart';
import '../repositories/offline_repository.dart';

final insumosRepositoryProvider = Provider<OfflineRepository<Insumo>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OfflineRepository<Insumo>(
    entityType: 'insumo',
    endpoint: 'insumos/',
    apiClient: apiClient,
    fromJson: Insumo.fromJson,
    toJson: (i) => i.toJson(),
    idOf: (i) => i.id,
    placeholderFields: () => {
      'usuario': 0,
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    },
  );
});

final insumosProvider = FutureProvider.autoDispose<List<Insumo>>((ref) async {
  final repo = ref.read(insumosRepositoryProvider);
  return repo.getAll();
});

// movimientos-inventario es el ledger de entradas/salidas, se queda
// online-only: no forma parte del alcance de BP-157/BP-159.
final movimientosProvider =
    FutureProvider.autoDispose<List<MovimientoInventario>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('movimientos-inventario/');
  return (response.data as List)
      .map((j) => MovimientoInventario.fromJson(j))
      .toList();
});

class InsumosNotifier extends StateNotifier<AsyncValue<List<Insumo>>> {
  final OfflineRepository<Insumo> _repo;
  final ApiClient _client;

  InsumosNotifier(this._repo, this._client)
      : super(const AsyncValue.loading()) {
    fetchInsumos();
  }

  Future<void> fetchInsumos() async {
    state = const AsyncValue.loading();
    try {
      final insumos = await _repo.getAll();
      state = AsyncValue.data(insumos);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> createInsumo(Map<String, dynamic> data) async {
    try {
      await _repo.create(data);
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateInsumo(int id, Map<String, dynamic> data) async {
    try {
      await _repo.update(id, data);
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInsumo(int id) async {
    try {
      await _repo.delete(id);
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }

  // Registra un movimiento de inventario (entrada/salida). Requiere
  // conexión: impacta el stock del insumo en el servidor y queda fuera
  // del alcance de BP-157/BP-159. Sin cambios.
  Future<void> addMovimiento(int insumoId, String tipo, double cantidad,
      {double? costoUnitario, String? notas}) async {
    try {
      await _client.dio.post('movimientos-inventario/', data: {
        'insumo': insumoId,
        'tipo_movimiento': tipo,
        'cantidad_kg': cantidad.toString(),
        if (costoUnitario != null)
          'costo_unitario_kg': costoUnitario.toString(),
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      });
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }
}

final insumosNotifierProvider = StateNotifierProvider.autoDispose<
    InsumosNotifier, AsyncValue<List<Insumo>>>((ref) {
  return InsumosNotifier(
    ref.read(insumosRepositoryProvider),
    ref.read(apiClientProvider),
  );
});
