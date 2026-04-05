import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/lote.dart';

final lotesProvider = FutureProvider.autoDispose<List<Lote>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('lotes/');
  return (response.data as List).map((j) => Lote.fromJson(j)).toList();
});

class LotesNotifier extends StateNotifier<AsyncValue<List<Lote>>> {
  final ApiClient _client;

  LotesNotifier(this._client) : super(const AsyncValue.loading()) {
    fetchLotes();
  }

  Future<void> fetchLotes() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.dio.get('lotes/');
      final lotes = (response.data as List).map((j) => Lote.fromJson(j)).toList();
      state = AsyncValue.data(lotes);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> createLote(Map<String, dynamic> data) async {
    try {
      await _client.dio.post('lotes/', data: data);
      await fetchLotes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLote(int id, Map<String, dynamic> data) async {
    try {
      await _client.dio.patch('lotes/$id/', data: data);
      await fetchLotes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLote(int id) async {
    try {
      await _client.dio.delete('lotes/$id/');
      await fetchLotes();
    } catch (e) {
      rethrow;
    }
  }
}

final lotesNotifierProvider = StateNotifierProvider.autoDispose<LotesNotifier, AsyncValue<List<Lote>>>((ref) {
  return LotesNotifier(ref.read(apiClientProvider));
});
