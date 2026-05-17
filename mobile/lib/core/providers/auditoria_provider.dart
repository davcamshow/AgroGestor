import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auditoria_animal.dart';
import '../api/api_client.dart';

final auditoriaAnimalProvider = FutureProvider.autoDispose
    .family<List<AuditoriaAnimal>, int>((ref, animalId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('animales/$animalId/auditoria/');
  return (response.data as List)
      .map((j) => AuditoriaAnimal.fromJson(j))
      .toList();
});
