import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal.dart';
import '../api/api_client.dart';

class AnimalesNotifier extends AutoDisposeAsyncNotifier<List<Animal>> {
  @override
  Future<List<Animal>> build() async {
    final client = ref.read(apiClientProvider);
    // Por defecto solo trae activos (estado=activo es el default del backend)
    final response = await client.dio.get('animales/');
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
}

final animalesNotifierProvider =
    AsyncNotifierProvider.autoDispose<AnimalesNotifier, List<Animal>>(
        AnimalesNotifier.new);

// --- Filtros ---

/// Estado seleccionado en el listado: 'activo' | 'todos' | 'vendido' | 'muerto' | 'transferido'
final animalesEstadoFiltroProvider =
    StateProvider.autoDispose<String>((ref) => 'activo');

/// Filtros adicionales (sexo, etc.)
final animalesFilterProvider =
    StateProvider.autoDispose<Map<String, String>>((ref) => {});
