import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/evento_sanitario.dart';
import '../api/api_client.dart';
import '../repositories/offline_repository.dart';

final eventosSanitariosRepositoryProvider =
    Provider<OfflineRepository<EventoSanitario>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OfflineRepository<EventoSanitario>(
    entityType: 'evento_sanitario',
    endpoint: 'eventos-sanitarios/',
    apiClient: apiClient,
    fromJson: EventoSanitario.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
  );
});

class EventosSanitariosNotifier
    extends AutoDisposeAsyncNotifier<List<EventoSanitario>> {
  @override
  Future<List<EventoSanitario>> build() async {
    final repo = ref.read(eventosSanitariosRepositoryProvider);
    return repo.getAll();
  }

  Future<void> createEvento(Map<String, dynamic> data) async {
    final repo = ref.read(eventosSanitariosRepositoryProvider);
    await repo.create(data);
    ref.invalidateSelf();
  }

  Future<void> updateEvento(int id, Map<String, dynamic> data) async {
    final repo = ref.read(eventosSanitariosRepositoryProvider);
    await repo.update(id, data);
    ref.invalidateSelf();
  }

  Future<void> deleteEvento(int id) async {
    final repo = ref.read(eventosSanitariosRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final eventosSanitariosNotifierProvider = AsyncNotifierProvider.autoDispose<
    EventosSanitariosNotifier,
    List<EventoSanitario>>(EventosSanitariosNotifier.new);

// Provider para eventos próximos (proximos 30 dias)
final eventosProximosProvider =
    FutureProvider.autoDispose<List<EventoSanitario>>((ref) async {
  final eventos = await ref.watch(eventosSanitariosNotifierProvider.future);
  final ahora = DateTime.now();
  return eventos
      .where((e) =>
          e.proximaAplicacion != null &&
          e.proximaAplicacion!.isAfter(ahora) &&
          e.proximaAplicacion!.isBefore(ahora.add(const Duration(days: 30))))
      .toList();
});
