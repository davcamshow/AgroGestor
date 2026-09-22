import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notificacion.dart';
import '../models/preferencia_notificacion.dart';
import '../api/api_client.dart';

class NotificacionesNotifier
    extends AutoDisposeAsyncNotifier<List<Notificacion>> {
  @override
  Future<List<Notificacion>> build() async {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get('notificaciones/');
    return (response.data as List)
        .map((j) => Notificacion.fromJson(j))
        .toList();
  }

  Future<void> marcarLeida(int id) async {
    final client = ref.read(apiClientProvider);
    await client.dio.patch('notificaciones/$id/marcar_leida/');
    ref.invalidateSelf();
  }

  Future<void> marcarTodasLeidas() async {
    final client = ref.read(apiClientProvider);
    await client.dio.post('notificaciones/marcar_todas_leidas/');
    ref.invalidateSelf();
  }
}

final notificacionesNotifierProvider = AsyncNotifierProvider.autoDispose<
    NotificacionesNotifier, List<Notificacion>>(NotificacionesNotifier.new);

final notificacionesNoLeidasProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final notifs = await ref.watch(notificacionesNotifierProvider.future);
  return notifs.where((n) => !n.leida).length;
});

final preferenciaNotificacionProvider =
    FutureProvider.autoDispose<PreferenciaNotificacion>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('preferencias-notificaciones/');
  return PreferenciaNotificacion.fromJson(response.data);
});

Future<void> actualizarPreferenciaNotificacion(
  WidgetRef ref,
  Map<String, dynamic> data,
) async {
  final client = ref.read(apiClientProvider);
  await client.dio.patch('preferencias-notificaciones/', data: data);
  ref.invalidate(preferenciaNotificacionProvider);
}
