import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/registro_peso.dart';
import '../api/api_client.dart';

class RegistrosPesoNotifier extends AsyncNotifier<List<RegistroPeso>> {
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

  Future<void> updateRegistro(int id, Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    await client.dio.put('registros-peso/$id/', data: data);
    ref.invalidateSelf();
  }

  Future<void> deleteRegistro(int id) async {
    final client = ref.read(apiClientProvider);
    await client.dio.delete('registros-peso/$id/');
    ref.invalidateSelf();
  }
}

final registrosPesoNotifierProvider =
    AsyncNotifierProvider.autoDispose<RegistrosPesoNotifier, List<RegistroPeso>>(
        RegistrosPesoNotifier.new);
