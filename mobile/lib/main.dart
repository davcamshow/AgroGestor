import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/services/push_notification_service.dart';
import 'core/providers/sync_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() => runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await PushNotificationService().init(
        oneSignalAppId: 'ONESIGNAL_APP_ID',
      );
      // 1. Lee SharedPreferences antes de montar el árbol de widgets
      final prefs = await SharedPreferences.getInstance();

      await dotenv.load(fileName: '.env');
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint("Aviso: No se pudo cargar .env: $e");
      }

      // Obtener App ID asegurando que no sea el placeholder
      String appId = dotenv.maybeGet('ONESIGNAL_APP_ID')?.trim() ?? '';
      if (appId.isEmpty || appId == 'ONESIGNAL_APP_ID') {
        appId = '53284d44-8273-4f11-9d8a-693546975f9e'; // Tu ID real de Bovion
      }

      // Inicializar OneSignal con el ID resuelto
      OneSignal.initialize(appId);
      OneSignal.Notifications.requestPermission(true);
      await Supabase.initialize(
        url: 'https://vcxdtkekiweomnemfwdk.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjeGR0a2VraXdlb21uZW1md2RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyODA5MDUsImV4cCI6MjA5NDg1NjkwNX0._zc6NGfUSWE-yB09l_4nVAXjvAPY82pS5_kOwicRRYk',
      );

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      runApp(
        ProviderScope(
          overrides: [
            // 2. Inyecta la instancia leída al provider
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const BovionApp(),
        ),
      );
    }, (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
    });

class BovionApp extends ConsumerWidget {
  const BovionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(
        syncServiceProvider); // BP-159: activa el listener de conectividad

    return MaterialApp.router(
      title: 'Bovion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
