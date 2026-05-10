import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/registro_peso.dart';
import '../api/api_client.dart';

class RegistroPesoNotifier extends AutoDisposeAsyncNotifier<List<RegistroPeso>> {
  @override
  Future<List<RegistroPeso>> build() async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get('registros-peso/');
    return (response.data as List).map((j) => RegistroPeso.fromJson(j)).toList();
  }

  Future<void> createRegistro(Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.post('registros-peso/', data: data);
    ref.invalidateSelf();
  }

  Future<void> deleteRegistro(int id) async {
    final client = ref.read(apiClientProvider);
    await client.dio.delete('registros-peso/$id/');
    ref.invalidateSelf();
  }
}

final registroPesoNotifierProvider =
    AsyncNotifierProvider.autoDispose<RegistroPesoNotifier, List<RegistroPeso>>(
        RegistroPesoNotifier.new);

final registrosPesoAnimalProvider = FutureProvider.family<List<RegistroPeso>, int>((ref, animalId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('registros-peso/?animal=$animalId');
  return (response.data as List).map((j) => RegistroPeso.fromJson(j)).toList();
});
