import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ciclo_reproductivo.dart';
import '../api/api_client.dart';

class CiclosNotifier extends AutoDisposeAsyncNotifier<List<CicloReproductivo>> {
  @override
  Future<List<CicloReproductivo>> build() async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get('ciclos-reproductivos/');
    return (response.data as List).map((j) => CicloReproductivo.fromJson(j)).toList();
  }

  Future<void> createCiclo(Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.post('ciclos-reproductivos/', data: data);
    ref.invalidateSelf();
  }

  Future<void> updateCiclo(int id, Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.put('ciclos-reproductivos/$id/', data: data);
    ref.invalidateSelf();
  }

  Future<void> deleteCiclo(int id) async {
    final client = ref.read(apiClientProvider);
    await client.dio.delete('ciclos-reproductivos/$id/');
    ref.invalidateSelf();
  }
}

final ciclosNotifierProvider =
    AsyncNotifierProvider.autoDispose<CiclosNotifier, List<CicloReproductivo>>(
        CiclosNotifier.new);

// Provider para ciclos gestantes
final ciclosGestantesProvider = FutureProvider.autoDispose<List<CicloReproductivo>>((ref) async {
  final ciclos = await ref.watch(ciclosNotifierProvider.future);
  return ciclos.where((c) => c.estado == 'gestante').toList();
});
