import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/evento_sanitario.dart';
import '../api/api_client.dart';

class EventosSanitariosNotifier extends AutoDisposeAsyncNotifier<List<EventoSanitario>> {
  @override
  Future<List<EventoSanitario>> build() async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get('eventos-sanitarios/');
    return (response.data as List).map((j) => EventoSanitario.fromJson(j)).toList();
  }

  Future<void> createEvento(Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.post('eventos-sanitarios/', data: data);
    ref.invalidateSelf();
  }

  Future<void> updateEvento(int id, Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.put('eventos-sanitarios/$id/', data: data);
    ref.invalidateSelf();
  }

  Future<void> deleteEvento(int id) async {
    final client = ref.read(apiClientProvider);
    await client.dio.delete('eventos-sanitarios/$id/');
    ref.invalidateSelf();
  }
}

final eventosSanitariosNotifierProvider =
    AsyncNotifierProvider.autoDispose<EventosSanitariosNotifier, List<EventoSanitario>>(
        EventosSanitariosNotifier.new);

// Provider para eventos próximos (proximos 30 dias)
final eventosProximosProvider = FutureProvider.autoDispose<List<EventoSanitario>>((ref) async {
  final eventos = await ref.watch(eventosSanitariosNotifierProvider.future);
  final ahora = DateTime.now();
  return eventos
      .where((e) =>
          e.proximaAplicacion != null &&
          e.proximaAplicacion!.isAfter(ahora) &&
          e.proximaAplicacion!.isBefore(ahora.add(const Duration(days: 30))))
      .toList();
});
