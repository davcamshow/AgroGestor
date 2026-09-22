import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../services/sync_service.dart';

/// Provider (no autoDispose) para que el listener de conectividad se cree
/// una sola vez al arrancar la app y viva durante toda la sesión. Se
/// inicializa observándolo en `BovionApp.build` (ver main.dart).
final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final service = SyncService(apiClient);
  ref.onDispose(service.dispose);
  return service;
});

/// Estado de la última sincronización, para mostrar un indicador en la UI
/// (ej. un banner o icono en el AppBar) si se desea.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.statusStream;
});
