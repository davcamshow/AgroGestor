import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

const String oneSignalAppId =
    'f3e5c1d0-7b8a-4f6e-9c2b-1a2b3c4d5e6f'; // Reemplaza con tu OneSignal App ID

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

class PushNotificationService {
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    OneSignal.initialize(oneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);

    // Notificación recibida con la app en primer plano: se muestra igual
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    // Usuario toca la notificación
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      print('[PUSH] Notificación tocada: $data');
      // Aquí puedes navegar según data?['tipo'] / data?['referencia_id']
    });
  }

  /// Llamar tras login exitoso — asocia este dispositivo con el usuario Django
  Future<void> loginUsuario(int usuarioId) async {
    await OneSignal.login(usuarioId.toString());
  }

  /// Llamar en logout — desasocia el dispositivo del usuario
  Future<void> logoutUsuario() async {
    await OneSignal.logout();
  }
}
