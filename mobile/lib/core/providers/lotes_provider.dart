import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/lote.dart';
import '../repositories/offline_repository.dart';

final lotesRepositoryProvider = Provider<OfflineRepository<Lote>>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OfflineRepository<Lote>(
    entityType: 'lote',
    endpoint: 'lotes/',
    apiClient: apiClient,
    fromJson: Lote.fromJson,
    toJson: (l) => l.toJson(),
    idOf: (l) => l.id,
    placeholderFields: () => {
      'usuario': 0,
      'fecha_registro': DateTime.now().toIso8601String(),
    },
  );
});

final lotesProvider = FutureProvider.autoDispose<List<Lote>>((ref) async {
  final repo = ref.read(lotesRepositoryProvider);
  return repo.getAll();
});

class LotesNotifier extends StateNotifier<AsyncValue<List<Lote>>> {
  final OfflineRepository<Lote> _repo;

  LotesNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchLotes();
  }

  Future<void> fetchLotes() async {
    state = const AsyncValue.loading();
    try {
      final lotes = await _repo.getAll();
      state = AsyncValue.data(lotes);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> createLote(Map<String, dynamic> data) async {
    try {
      await _repo.create(data);
      await fetchLotes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLote(int id, Map<String, dynamic> data) async {
    try {
      await _repo.update(id, data);
      await fetchLotes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLote(int id) async {
    try {
      await _repo.delete(id);
      await fetchLotes();
    } catch (e) {
      rethrow;
    }
  }
}

final lotesNotifierProvider =
    StateNotifierProvider.autoDispose<LotesNotifier, AsyncValue<List<Lote>>>(
        (ref) {
  return LotesNotifier(ref.read(lotesRepositoryProvider));
});
