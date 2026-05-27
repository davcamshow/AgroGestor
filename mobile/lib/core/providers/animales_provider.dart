import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal.dart';
import '../api/api_client.dart';

class AnimalesNotifier extends AutoDisposeAsyncNotifier<List<Animal>> {
  @override
  Future<List<Animal>> build() async {
    final client = ref.read(apiClientProvider);

    // Leer el estado actual del filtro (activo, todos, vendido, etc.)
    final estado = ref.watch(animalesEstadoFiltroProvider);
    final filtrosAdicionales = ref.watch(animalesFilterProvider);

    // Construir los query parameters dinámicamente
    final queryParams = <String, dynamic>{
      'estado': estado,
      ...filtrosAdicionales,
    };

    final response =
        await client.dio.get('animales/', queryParameters: queryParams);
    return (response.data as List).map((j) => Animal.fromJson(j)).toList();
  }

  Future<int> createAnimal(Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.post('animales/', data: data);
    ref.invalidateSelf();
    return response.data['id'] as int;
  }

  Future<void> updateAnimal(int id, Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.put('animales/$id/', data: data);
    ref.invalidateSelf();
  }

  Future<void> deleteAnimal(int id) async {
    final client = ref.read(apiClientProvider);
    await client.dio.delete('animales/$id/');
    ref.invalidateSelf();
  }

  /// Registra la baja lógica de un animal (venta, muerte, transferencia).
  /// El backend cambia el estado y lo desvincula del lote automáticamente.
  Future<Map<String, dynamic>> registrarBaja({
    required int animalId,
    required String causa, // 'vendido' | 'muerto' | 'transferido'
    required String fecha, // 'YYYY-MM-DD'
    String notas = '',
  }) async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.post(
      'animales/$animalId/baja/',
      data: {
        'causa': causa,
        'fecha': fecha,
        'notas': notas,
      },
    );
    // Refrescar el listado para que el animal dado de baja desaparezca
    ref.invalidateSelf();
    return response.data as Map<String, dynamic>;
  }

  /// Realiza el traslado de un animal de un lote a otro.
  /// Impacta el endpoint custom del backend recalculando contadores y auditando el evento.
  Future<Map<String, dynamic>> moverLote({
    required int animalId,
    required int? loteOrigenId,
    required int loteDestinoId,
    required String fechaMovimiento, // Formato esperado 'YYYY-MM-DD'
    String notas = '',
  }) async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.post(
      'animales/$animalId/mover-lote/',
      data: {
        'lote_origen_id': loteOrigenId,
        'lote_destino_id': loteDestinoId,
        'fecha_movimiento': fechaMovimiento,
        'notas': notas,
      },
    );
    // Invalida el estado actual para refrescar la información en detalle e historial de forma inmediata
    ref.invalidateSelf();
    return response.data as Map<String, dynamic>;
  }
}

final animalesNotifierProvider =
    AsyncNotifierProvider.autoDispose<AnimalesNotifier, List<Animal>>(
        AnimalesNotifier.new);

// --- Filtros ---

/// Estado seleccionado en el listado: 'activo' | 'todos' | 'vendido' | 'muerto' | 'transferido'
final animalesEstadoFiltroProvider =
    StateProvider.autoDispose<String>((ref) => 'todos');

/// Filtros adicionales (sexo, etc.)
final animalesFilterProvider =
    StateProvider.autoDispose<Map<String, String>>((ref) => {});
