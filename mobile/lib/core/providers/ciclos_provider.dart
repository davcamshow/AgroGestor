import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ciclo_reproductivo.dart';
import '../api/api_client.dart';
import '../repositories/offline_repository.dart';

final ciclosRepositoryProvider =
    Provider<OfflineRepository<CicloReproductivo>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OfflineRepository<CicloReproductivo>(
    entityType: 'ciclo_reproductivo',
    endpoint: 'ciclos-reproductivos/',
    apiClient: apiClient,
    fromJson: CicloReproductivo.fromJson,
    toJson: (c) => c.toJson(),
    idOf: (c) => c.id,
    // Valores de respaldo por si el formulario no los manda explícitos
    // (el backend los defaultea: dias_gestacion=283, estado='en_servicio').
    // 'data' siempre gana sobre estos si el formulario sí los incluye.
    placeholderFields: () => {
      'dias_gestacion': 283,
      'estado': 'en_servicio',
    },
  );
});

class CiclosNotifier extends AutoDisposeAsyncNotifier<List<CicloReproductivo>> {
  @override
  Future<List<CicloReproductivo>> build() async {
    final repo = ref.read(ciclosRepositoryProvider);
    return repo.getAll();
  }

  Future<void> createCiclo(Map<String, dynamic> data) async {
    final repo = ref.read(ciclosRepositoryProvider);
    await repo.create(data);
    ref.invalidateSelf();
  }

  Future<void> updateCiclo(int id, Map<String, dynamic> data) async {
    final repo = ref.read(ciclosRepositoryProvider);
    await repo.update(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteCiclo(int id) async {
    final repo = ref.read(ciclosRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }

  // registrar-parto y nacimientos son acciones/recursos de servidor con
  // efectos secundarios (cierran el ciclo, crean el animal cría). Requieren
  // conexión, fuera del alcance de BP-157/BP-159. Sin cambios.

  Future<Map<String, dynamic>> registrarParto(int cicloId) async {
    final client = ref.read(apiClientProvider);
    final response =
        await client.dio.post('ciclos-reproductivos/$cicloId/registrar-parto/');
    ref.invalidateSelf();
    return response.data as Map<String, dynamic>;
  }

  Future<void> registrarNacimiento(Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.post('nacimientos/', data: data);
    ref.invalidateSelf();
  }
}

final ciclosNotifierProvider =
    AsyncNotifierProvider.autoDispose<CiclosNotifier, List<CicloReproductivo>>(
        CiclosNotifier.new);

// Provider para ciclos gestantes
final ciclosGestantesProvider =
    FutureProvider.autoDispose<List<CicloReproductivo>>((ref) async {
  final ciclos = await ref.watch(ciclosNotifierProvider.future);
  return ciclos.where((c) => c.estado == 'gestante').toList();
});
