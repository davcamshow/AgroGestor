import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal.dart';
import '../api/api_client.dart';
import '../repositories/offline_repository.dart';

/// Repositorio offline-first para Animal. `usuario` y `fecha_registro` los
/// asigna el servidor (read_only en el backend); se les da un valor de
/// relleno mientras el registro creado offline no ha sido sincronizado.
final animalesRepositoryProvider = Provider<OfflineRepository<Animal>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OfflineRepository<Animal>(
    entityType: 'animal',
    endpoint: 'animales/',
    apiClient: apiClient,
    fromJson: Animal.fromJson,
    toJson: (a) => a.toJson(),
    idOf: (a) => a.id,
    placeholderFields: () => {
      'usuario': 0,
      'fecha_registro': DateTime.now().toIso8601String(),
    },
  );
});

class AnimalesNotifier extends AutoDisposeAsyncNotifier<List<Animal>> {
  @override
  Future<List<Animal>> build() async {
    final repo = ref.read(animalesRepositoryProvider);

    // Leer el estado actual del filtro (activo, todos, vendido, etc.)
    final estado = ref.watch(animalesEstadoFiltroProvider);
    final filtrosAdicionales = ref.watch(animalesFilterProvider);

    // El repositorio offline-first trae/cachea la lista completa (no
    // acepta query params, para que la caché sirva igual estando online o
    // sin conexión). El filtrado por estado/sexo se aplica aquí en
    // memoria, igual que antes se hacía server-side.
    final animales = await repo.getAll();

    return animales.where((a) {
      if (estado != 'todos' && a.estado != estado) return false;
      if (filtrosAdicionales.containsKey('sexo') &&
          a.sexo != filtrosAdicionales['sexo']) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<FormData> _asMultipart(Map<String, dynamic> data, File foto) async {
    final map = <String, dynamic>{};
    data.forEach((key, value) {
      if (value != null) map[key] = value.toString();
    });
    final filename = foto.path.split(RegExp(r'[\\/]')).last;
    map['foto'] = await MultipartFile.fromFile(foto.path, filename: filename);
    return FormData.fromMap(map);
  }

  Future<int> createAnimal(Map<String, dynamic> data, {File? foto}) async {
    if (foto != null) {
      final client = ref.read(apiClientProvider);
      final response = await client.dio
          .post('animales/', data: await _asMultipart(data, foto));
      ref.invalidateSelf();
      return response.data['id'] as int;
    }
    final repo = ref.read(animalesRepositoryProvider);
    final animal = await repo.create(data);
    ref.invalidateSelf();
    return animal.id;
  }

  Future<void> updateAnimal(int id, Map<String, dynamic> data,
      {File? foto}) async {
    if (foto != null) {
      final client = ref.read(apiClientProvider);
      await client.dio
          .patch('animales/$id/', data: await _asMultipart(data, foto));
      ref.invalidateSelf();
      return;
    }
    final repo = ref.read(animalesRepositoryProvider);
    await repo.update(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteAnimal(int id) async {
    final repo = ref.read(animalesRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }

  /// Registra la baja lógica de un animal (venta, muerte, transferencia).
  /// El backend cambia el estado y lo desvincula del lote automáticamente.
  ///
  /// Requiere conexión: tiene efectos secundarios de servidor (recalcula
  /// contadores, audita el evento) que no tiene sentido encolar offline
  /// contra un animal que podría ni siquiera existir aún en el servidor.
  /// Fuera del alcance de BP-157/BP-159.
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
    ref.invalidateSelf();
    return response.data as Map<String, dynamic>;
  }

  /// Realiza el traslado de un animal de un lote a otro.
  ///
  /// Requiere conexión, mismo motivo que [registrarBaja]. Fuera del
  /// alcance de BP-157/BP-159.
  Future<Map<String, dynamic>> moverLote({
    required int animalId,
    required int? loteOrigenId,
    required int loteDestinoId,
    required String fechaMovimiento, // 'YYYY-MM-DD'
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

/// Texto de búsqueda del listado (filtra por número de arete o nombre).
final animalesBusquedaProvider = StateProvider.autoDispose<String>((ref) => '');

/// Filtros adicionales (sexo, etc.)
final animalesFilterProvider =
    StateProvider.autoDispose<Map<String, String>>((ref) => {});
