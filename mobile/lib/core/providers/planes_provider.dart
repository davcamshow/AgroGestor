import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/plan_suscripcion.dart';

final planesProvider = FutureProvider<List<PlanSuscripcion>>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('planes/');
  return (response as List).map((e) => PlanSuscripcion.fromJson(e)).toList();
});

final miPlanProvider = FutureProvider<InfoPlanUsuario>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('planes/mi-plan/');
  return InfoPlanUsuario.fromJson(response);
});

final cambiarPlanProvider = FutureProvider.family<void, String>((ref, planCodigo) async {
  final client = ref.read(apiClientProvider);
  await client.post('planes/cambiar/', data: {'plan_codigo': planCodigo});
  ref.invalidate(miPlanProvider);
  ref.invalidate(planesProvider);
});