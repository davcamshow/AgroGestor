import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal.dart';
import '../api/api_client.dart';

class AnimalesNotifier extends AsyncNotifier<List<Animal>> {
  @override
  Future<List<Animal>> build() async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get('animales/');
    return (response.data as List).map((j) => Animal.fromJson(j)).toList();
  }

  Future<void> createAnimal(Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.post('animales/', data: data);
    ref.invalidateSelf();
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
}

final animalesNotifierProvider =
    AsyncNotifierProvider.autoDispose<AnimalesNotifier, List<Animal>>(
        AnimalesNotifier.new);

final animalesFilterProvider =
    StateProvider.autoDispose<Map<String, String>>((ref) => {});
