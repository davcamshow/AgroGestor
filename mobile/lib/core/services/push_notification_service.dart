import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const String _defaultAppId = '53284d44-8273-4f11-9d8a-693546975f9e';
  bool _initialized = false;

  Future<void> init({String? oneSignalAppId}) async {
    if (_initialized) return;

    String resolvedAppId = (oneSignalAppId != null && oneSignalAppId.isNotEmpty)
        ? oneSignalAppId
        : (dotenv.maybeGet('ONESIGNAL_APP_ID') ?? '');

    if (resolvedAppId.isEmpty ||
        resolvedAppId == 'ONESIGNAL_APP_ID' ||
        resolvedAppId.contains('ONESIGNAL')) {
      resolvedAppId = _defaultAppId;
    }

    debugPrint(
        '[PushService] Inicializando OneSignal con AppId: $resolvedAppId');

    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    }

    OneSignal.initialize(resolvedAppId);

    final permisoAceptado =
        await OneSignal.Notifications.requestPermission(true);
    debugPrint('[PushService] Permiso de notificaciones: $permisoAceptado');

    _configurarListeners();
    _initialized = true;
  }

  void _configurarListeners() {
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint('==================================================');
      debugPrint('[PushService] CAMBIO EN PUSH SUBSCRIPTION:');
      debugPrint('Subscription ID: ${state.current.id}');
      debugPrint('Token FCM: ${state.current.token}');
      debugPrint('Opted In: ${state.current.optedIn}');
      debugPrint('==================================================');
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint(
          '[PushService] Notificación en primer plano: ${event.notification.title}');
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      debugPrint(
          '[PushService] Notificación clickeada: ${event.notification.title}');
    });
  }

  Future<void> loginUsuario(dynamic userId) async {
    if (userId == null) return;
    final externalId = userId.toString().trim();

    try {
      debugPrint('[PushService] Vinculando usuario: $externalId');
      await OneSignal.login(externalId);

      // Esperar brevemente para verificar si ya tomó suscripción
      await Future.delayed(const Duration(seconds: 2));
      imprimirEstadoDiagnostico();
    } catch (e) {
      debugPrint('[PushService] Error en loginUsuario: $e');
    }
  }

  Future<void> logoutUsuario() async {
    try {
      await OneSignal.logout();
      debugPrint('[PushService] Sesión desvinculada en OneSignal.');
    } catch (e) {
      debugPrint('[PushService] Error en logoutUsuario: $e');
    }
  }

  void imprimirEstadoDiagnostico() {
    final pushId = OneSignal.User.pushSubscription.id;
    final token = OneSignal.User.pushSubscription.token;
    final optedIn = OneSignal.User.pushSubscription.optedIn;

    debugPrint('================= DIAGNÓSTICO ONESIGNAL =================');
    debugPrint('Push Subscription ID: $pushId');
    debugPrint('Token FCM: $token');
    debugPrint('Opted In: $optedIn');
    debugPrint('========================================================');
  }

  // Aliases de conveniencia
  Future<void> login(dynamic userId) => loginUsuario(userId);
  Future<void> logout() => logoutUsuario();
}
