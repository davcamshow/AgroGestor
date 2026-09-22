import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/registro_peso.dart';
import '../api/api_client.dart';
import '../repositories/offline_repository.dart';

final registrosPesoRepositoryProvider =
    Provider<OfflineRepository<RegistroPeso>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OfflineRepository<RegistroPeso>(
    entityType: 'registro_peso',
    endpoint: 'registros-peso/',
    apiClient: apiClient,
    fromJson: RegistroPeso.fromJson,
    toJson: (r) => r.toJson(),
    idOf: (r) => r.id,
  );
});

class RegistroPesoNotifier
    extends AutoDisposeAsyncNotifier<List<RegistroPeso>> {
  @override
  Future<List<RegistroPeso>> build() async {
    final repo = ref.read(registrosPesoRepositoryProvider);
    return repo.getAll();
  }

  Future<void> createRegistro(Map<String, dynamic> data) async {
    final repo = ref.read(registrosPesoRepositoryProvider);
    await repo.create(data);
    ref.invalidateSelf();
  }

  Future<void> deleteRegistro(int id) async {
    final repo = ref.read(registrosPesoRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final registroPesoNotifierProvider =
    AsyncNotifierProvider.autoDispose<RegistroPesoNotifier, List<RegistroPeso>>(
        RegistroPesoNotifier.new);

/// Registros de peso de un animal específico. Antes filtraba server-side
/// con `?animal=$animalId`; el repositorio offline-first no acepta query
/// params (para que la caché sirva igual sin conexión), así que ahora se
/// filtra en memoria sobre el mismo listado cacheado/consultado.
final registrosPesoAnimalProvider =
    FutureProvider.family<List<RegistroPeso>, int>((ref, animalId) async {
  final repo = ref.read(registrosPesoRepositoryProvider);
  final registros = await repo.getAll();
  return registros.where((r) => r.animalId == animalId).toList();
});
