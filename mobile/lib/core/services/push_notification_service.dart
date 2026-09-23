import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void> init({required String oneSignalAppId}) async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);

    // Observer para capturar el Subscription ID en tiempo real
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint("==================================================");
      debugPrint("CAMBIO EN PUSH SUBSCRIPTION:");
      debugPrint("Subscription ID: ${state.current.id}");
      debugPrint("Token FCM: ${state.current.token}");
      debugPrint("Opted In: ${state.current.optedIn}");
      debugPrint("==================================================");
    });

    // Solicitar permisos de notificación
    final permission = await OneSignal.Notifications.requestPermission(true);
    debugPrint("Permiso de notificaciones concedido: $permission");

    // Permitir visualización en primer plano
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint(
          "Notificación recibida en foreground: ${event.notification.title}");
      event.notification.display();
    });
  }

  /// Asocia el ID del usuario de tu backend/BD con OneSignal (External ID)
  Future<void> loginUsuario(dynamic userId) async {
    try {
      final externalId = userId.toString();
      await OneSignal.login(externalId);
      debugPrint("OneSignal: Usuario logueado con External ID: $externalId");
    } catch (e) {
      debugPrint("Error al loguear usuario en OneSignal: $e");
    }
  }

  /// Desvincula el usuario actual de OneSignal al cerrar sesión
  Future<void> logoutUsuario() async {
    try {
      await OneSignal.logout();
      debugPrint("OneSignal: Sesión de usuario cerrada con éxito");
    } catch (e) {
      debugPrint("Error al desloguear usuario en OneSignal: $e");
    }
  }
}
