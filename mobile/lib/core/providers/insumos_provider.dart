import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/insumo.dart';
import '../models/movimiento_inventario.dart';

final insumosProvider = FutureProvider.autoDispose<List<Insumo>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('insumos/');
  return (response.data as List).map((j) => Insumo.fromJson(j)).toList();
});

final movimientosProvider = FutureProvider.autoDispose<List<MovimientoInventario>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('movimientos-inventario/');
  return (response.data as List).map((j) => MovimientoInventario.fromJson(j)).toList();
});

class InsumosNotifier extends StateNotifier<AsyncValue<List<Insumo>>> {
  final ApiClient _client;

  InsumosNotifier(this._client) : super(const AsyncValue.loading()) {
    fetchInsumos();
  }

  Future<void> fetchInsumos() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.dio.get('insumos/');
      final insumos = (response.data as List).map((j) => Insumo.fromJson(j)).toList();
      state = AsyncValue.data(insumos);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> createInsumo(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('insumos/', data: data);
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateInsumo(int id, Map<String, dynamic> data) async {
    try {
      await _client.dio.patch('insumos/$id/', data: data);
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInsumo(int id) async {
    try {
      await _client.dio.delete('insumos/$id/');
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addMovimiento(int insumoId, String tipo, double cantidad, {double? costoUnitario}) async {
    try {
      await _client.dio.post('movimientos-inventario/', data: {
        'insumo': insumoId,
        'tipo_movimiento': tipo,
        'cantidad_kg': cantidad.toString(),
        if (costoUnitario != null) 'costo_unitario_kg': costoUnitario.toString(),
      });
      await fetchInsumos();
    } catch (e) {
      rethrow;
    }
  }
}

final insumosNotifierProvider = StateNotifierProvider.autoDispose<InsumosNotifier, AsyncValue<List<Insumo>>>((ref) {
  return InsumosNotifier(ref.read(apiClientProvider));
});
